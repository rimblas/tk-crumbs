create or replace
package body tk_crumbs_api
as


--------------------------------------------------------------------------------
gc_scope_prefix constant VARCHAR2(31) := lower($$PLSQL_UNIT) || '.';

/* Constants */



-- Helper private function for managing the Crumb Navigation Stack
-- given a crumb id return the SEQ_ID if already present in the stack
-- otherwise return null
function crumb_seq_on_stack(p_id  in tk_crumbs.id%type)
  return tk_crumbs.seq_id%type
is
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'crumb_seq_on_stack';
  l_params logger.tab_param;

  l_seq_id  tk_crumbs.seq_id%type;
begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  -- logger.log('START', l_scope, null, l_params);

  select seq_id
    into l_seq_id
    from tk_crumbs
    where view_user = g_user
      and id = p_id;

  return l_seq_id;

  exception
    when NO_DATA_FOUND then
      return null;

    when OTHERS then
      logger.log_error('Unhandled Exception', l_scope, null, l_params);
      raise;
end crumb_seq_on_stack;




/**
* Return a JSON status object of the form:
* {"success": true}
* or
* {"success": false, "message": "FAILURE MESSAGE HERE"}
*
* @issue 
*
* @author Jorge Rimblas
* @created 2018-08-01
*/
procedure json_status(
      p_success in boolean default true
    , p_message in varchar2 default null
) 
as
    l_scope logger_logs.scope%type := gc_scope_prefix || 'json_status';
    l_params logger.tab_param;
begin
    logger.append_param(l_params, 'p_success', p_success);
    logger.append_param(l_params, 'p_message', p_message);
    logger.log('START', l_scope, null, l_params);

    apex_json.open_object;
    apex_json.write(
          p_name => 'success'
        , p_value => p_success
    );
    apex_json.write(
          p_name => 'message'
        , p_value => p_message
    );
    apex_json.close_object;

    logger.log('END', l_scope);
exception
    when others then
        logger.log_error('Unhandled Exception', l_scope, null, l_params);
        raise;
end json_status;






/**
 * PRIVATE
 * Add an entry to the stack
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created Tuesday, March 15, 2022
 * @param p_entity_type
 * @param p_entity_id
 */
procedure add_to_stack(
    p_entity_type  in tk_crumbs.entity_type%type
  , p_entity_id    in tk_crumbs.entity_id%type
)
is
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'add_to_stack';
  l_params logger.tab_param;

  l_seq_id tk_crumbs.seq_id%type;
begin
  logger.append_param(l_params, 'p_entity_type', p_entity_type);
  logger.append_param(l_params, 'p_entity_id', p_entity_id);
  logger.log('BEGIN', l_scope, null, l_params);

  select nvl(max(seq_id),0) + 1 
    into l_seq_id
    from tk_crumbs
   where view_user = g_user
     and entity_type = p_entity_type;

  insert into tk_crumbs(
      view_user
    , entity_type
    , entity_id
    , seq_id
    , active_ind
    , current_flag
  )
  select g_user
       , p_entity_type
       , p_entity_id
       , next_seq_id
       , 'Y' active_ind
       , 'Y' current_flag
    from (
    select nvl(max(seq_id),0) + 1 next_seq_id
      from tk_crumbs
     where view_user = g_user
       and entity_type = p_entity_type
    );

  logger.log('END', l_scope, null, l_params);

  exception
    when OTHERS then
      logger.log_error('Unhandled Exception', l_scope, null, l_params);
      raise;
end add_to_stack;





/**
 * PRIVATE
 * The provided id will be ACTIVE and CURRENT. This will be the ONLY CURRENT entry.
 * Entries to the "left" (meaning lower seq_id) will be "ACTIVE".
 * Entries to the "right" (meaning higer seq_id) will be "INACTIVE".

 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created Tuesday, March 15, 2022
 * @param x_result_status
 * @return
 */
procedure update_stack_pointer(
    p_entity_type  in tk_crumbs.entity_type%type
  , p_id           in tk_crumbs.id%type      default null
  , p_seq_id       in tk_crumbs.seq_id%type  default null
)
is
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'update_stack_pointer';
  l_params logger.tab_param;

  l_seq_id tk_crumbs.seq_id%type;
  l_active_ind tk_crumbs.active_ind%type;
  l_current_flag tk_crumbs.current_flag%type;

begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  logger.log('BEGIN', l_scope, null, l_params);

  if p_id is not null then
    l_seq_id := crumb_seq_on_stack(p_id);
  elsif p_seq_id is not null then
    l_seq_id := p_seq_id;
  end if;

  -- clear entries to the left
  for i in (
    select id, seq_id, max(seq_id) over () max_seq_id 
      from tk_crumbs 
     where view_user = g_user
       and entity_type = p_entity_type
     order by seq_id
     for update of active_ind, current_flag
  )
  loop
    if i.seq_id < nvl(l_seq_id, i.max_seq_id) then
      l_active_ind := 'Y';
      l_current_flag := '';
    elsif i.seq_id = nvl(l_seq_id, i.max_seq_id) then
      l_active_ind := 'Y';
      l_current_flag := 'Y';
    else
      l_active_ind := 'N';
      l_current_flag := '';
    end if;

    update tk_crumbs
      set active_ind = l_active_ind
        , current_flag = l_current_flag
    where id = i.id;

  end loop;  

  logger.log('END', l_scope, null, l_params);

  exception
    when OTHERS then
      logger.log_error('Unhandled Exception', l_scope, null, l_params);
      raise;
end update_stack_pointer;





/**
 * Given an entity return the ID if already present in the stack
 * otherwise return null
 *
 *
 * @example
 * 
 * @issue
 *
 * @author Jorge Rimblas
 * @created Tuesday, March 15, 2022
 * @param p_entity_type
 * @param p_entity_id
 * @return tk_crumbs.id%type
 */
function crumb_on_stack(
    p_entity_type  in tk_crumbs.entity_type%type
  , p_entity_id    in tk_crumbs.entity_id%type
  )
  return tk_crumbs.id%type
is
  -- l_scope  logger_logs.scope%type := gc_scope_prefix || 'crumb_on_stack';
  -- l_params logger.tab_param;

  l_id  tk_crumbs.id%TYPE;
begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  -- logger.log('START', l_scope, null, l_params);

  select id
    into l_id
    from tk_crumbs
   where view_user = g_user
     and entity_type = p_entity_type
     and entity_id = p_entity_id;

  return l_id;

  exception
    when NO_DATA_FOUND then
      return null;

    when OTHERS then
      -- logger.log_error('Unhandled Exception', l_scope, null, l_params);
      raise;
end crumb_on_stack;





-- The stack attempts to only have one crumb be CURRENT.  This function
-- returns the record(sec, entry_id, etc) with the CURRENT crumb or NULL if none found.
function get_current_stack_entry(p_entity_type  in tk_crumbs.entity_type%type) return tk_crumbs%rowtype
is
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'get_current_stack_entry';
  l_params logger.tab_param;

  l_rec  tk_crumbs%rowtype;
begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  -- logger.log('START', l_scope, null, l_params);

  select *
    into l_rec
    from tk_crumbs
   where entity_type = p_entity_type
     and view_user = g_user
     and current_flag = 'Y'
   fetch first 1 rows only;  -- we expect only one but add protection

  return l_rec;

  exception
    when NO_DATA_FOUND then
      return null;
    when OTHERS then
      logger.log_error('Unhandled Exception', l_scope, null, l_params);
      raise;
end get_current_stack_entry;






procedure reset_crumb_stack(
  p_entity_type  in tk_crumbs.entity_type%type
)
is
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'reset_crumb_stack';
  l_params logger.tab_param;
begin
  -- logger.append_param(l_params, 'p_entity_type', p_entity_type);
  -- logger.log('BEGIN', l_scope, null, l_params);

  delete from tk_crumbs where view_user = g_user and entity_type = p_entity_type;

  -- logger.log('END', l_scope, null, l_params);

  exception
    when OTHERS then
      logger.log_error('Unhandled Exception', l_scope, null, l_params);
      raise;
end reset_crumb_stack;




/**
 * If the crumb already exists on the stack, make it current
 *
 *
 * @example
 * 
 * @author Jorge Rimblas
 * @created Monday, March 14, 2022
 * @param p_entity_type
 * @param p_entity_id
 */
procedure touch(
    p_entity_type  in tk_crumbs.entity_type%type
  , p_entity_id    in tk_crumbs.entity_id%type
)
is
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'touch';
  l_params logger.tab_param;

  l_id                tk_crumbs.id%TYPE;
  l_cnt               number;
begin
--  logger.append_param(l_params, 'p_entity_type', p_entity_type);
--  logger.append_param(l_params, 'p_entity_id', p_entity_id);
--  logger.log('BEGIN', l_scope, null, l_params);

  l_id := crumb_on_stack(p_entity_type, p_entity_id);
  if l_id is not null then
    -- entity already on the stack, make it ACTIVE and CURRENT
    update_stack_pointer(p_entity_type => p_entity_type, p_id => l_id);
  end if;

end touch;






/**
 * Add crumb entity to the the navigation stack
 *
 *
 * @example
 * 
 * @author Jorge Rimblas
 * @created Monday, March 14, 2022
 * @param p_entity_type
 * @param p_entity_id
 * @return number of entries in the stack
 */
function push(
    p_entity_type  in tk_crumbs.entity_type%type
  , p_entity_id    in tk_crumbs.entity_id%type
)
  return number
is
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'push';
  l_params logger.tab_param;

  l_id                tk_crumbs.id%TYPE;
  l_cnt               number;
begin
--  logger.append_param(l_params, 'p_entity_id', p_entity_id);
--  logger.log('BEGIN', l_scope, null, l_params);

  l_id := crumb_on_stack(p_entity_type, p_entity_id);
  if l_id is not null then
    -- entity already on the stack, make it ACTIVE and CURRENT
    update_stack_pointer(p_entity_type => p_entity_type, p_id => l_id);
  else
    add_to_stack(
        p_entity_type     => p_entity_type
      , p_entity_id       => p_entity_id
    );
    update_stack_pointer(p_entity_type => p_entity_type, p_id => null);
  end if;

  select count(*) into l_cnt from tk_crumbs where view_user = g_user and entity_type = p_entity_type;

 -- logger.log('END', l_scope, null, l_params);

  return l_cnt;

  exception
    when OTHERS then
      -- logger.log_error('Unhandled Exception', l_scope, null, l_params);
      raise;
end push;




-- Overloaded push
procedure push(
    p_entity_type  in tk_crumbs.entity_type%type
  , p_entity_id    in tk_crumbs.entity_id%type
)
is
    l_cnt               number;
begin
  l_cnt := push(p_entity_type => p_entity_type, p_entity_id => p_entity_id);
end push;


/*
-- Overloaded push for AJAX calls
* @param apex_application.g_x01 implicit
* @return JSON {success:true}
*/
procedure push
is
    l_cnt               number;
begin
  l_cnt := push(p_entity_type => apex_application.g_x01, p_entity_id => apex_application.g_x02);

  json_status;


  exception
    when OTHERS then
      json_status(false, sqlerrm);
end push;





-- Return the the entry to go back to form the stack
function pop(p_entity_type in tk_crumbs.entity_type%type) return tk_crumbs.id%type
is
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'pop';
  l_params logger.tab_param;

  l_stack_rec   tk_crumbs%ROWTYPE;
begin
  -- logger.append_param(l_params, 'p_param1', p_param1);
  -- logger.log('BEGIN', l_scope, null, l_params);

  l_stack_rec := get_current_stack_entry(p_entity_type => p_entity_type);
  if l_stack_rec.seq_id is null or l_stack_rec.seq_id <= 1 then
    -- the stack is empty
    return null;
  else

    -- move the current pointer to the left (seq_id - 1)
    update_stack_pointer(p_entity_type => p_entity_type, p_seq_id => l_stack_rec.seq_id - 1);
    l_stack_rec := get_current_stack_entry(p_entity_type => p_entity_type);

    return l_stack_rec.id;
  end if;

  -- logger.log('END', l_scope, null, l_params);

  exception
    when OTHERS then
      logger.log_error('Unhandled Exception', l_scope, null, l_params);
      raise;
end pop;





/**
 * Removes a crumb from the stack if a user clicks on x (removeCrumb class)
 *
 *
 * @example
 * 
 * @author Jorge Rimblas
 * @created Monday, March 14, 2022
 * @param p_entity_id
 */
procedure remove_crumb(p_id  in tk_crumbs.id%type)
is
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'remove_crumb';
  l_params logger.tab_param;

  l_seq_id      tk_crumbs.seq_id%type;
begin
   delete
     from tk_crumbs
    where view_user = g_user
      and id = p_id;

 exception
    when OTHERS then
      logger.log_error('Unhandled Exception', l_scope, null, l_params);
      raise;
end remove_crumb;




/**
 * Overloaded call on remove_crumb
 * Will use apex_application.g_x01 as a parameter and it is meant to be called
 * form AJAX and returns {success:true}
 *
 * @example
 *
 * Create an OnDemand Process called 'REMOVE_CRUMB'
 * with the code `tk_crumbs_api.remove_crumb;`
 * This code is called by the js:
 * `tk.crumbs.removeCrumb(crumbID);`
 *
 * 
 * @author Jorge Rimblas
 * @created Monday, March 14, 2022
 * @param apex_application.g_x01 implicit
 * @return JSON {success:true}
 */
procedure remove_crumb
is
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'remove_crumb2';
  l_params logger.tab_param;

begin
   remove_crumb(p_id => apex_application.g_x01);

   json_status;

 exception
    when OTHERS then
      json_status(false, sqlerrm);
      logger.log_error('Unhandled Exception', l_scope, null, l_params);
end remove_crumb;






/**
 * Toggles a crumb as completed, used when the crumbs are action items
 *
 *
 * @example
 * 
 * @author Jorge Rimblas
 * @created Monday, March 21, 2022
 * @param p_entity_id
 */
procedure toggle_crumb_done(p_id  in tk_crumbs.id%type)
is
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'toggle_crumb_done';
  l_params logger.tab_param;

  l_seq_id      tk_crumbs.seq_id%type;
begin
   update tk_crumbs
      set completed_flag = decode(completed_flag, null, 'Y', null)
    where view_user = g_user
      and id = p_id;

 exception
    when OTHERS then
      logger.log_error('Unhandled Exception', l_scope, null, l_params);
      raise;
end toggle_crumb_done;




/**
 * Overloaded call on toggle_crumb_done
 * Will use apex_application.g_x01 as a parameter and it is meant to be called
 * form AJAX and returns {success:true}
 *
 * @example
 *
 * Create an OnDemand Process called 'COMPLETE_CRUMB'
 * with the code `tk_crumbs_api.toggle_crumb_done;`
 * This code is called by the js:
 * `tk.crumbs.completeCrumb(crumbID);`
 *
 * 
 * @author Jorge Rimblas
 * @created Monday, March 14, 2022
 * @param apex_application.g_x01 implicit
 * @return JSON {success:true}
 */
procedure toggle_crumb_done
is
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'toggle_crumb_done2';
  l_params logger.tab_param;

begin
   toggle_crumb_done(p_id => apex_application.g_x01);

   json_status;

 exception
    when OTHERS then
      json_status(false, sqlerrm);
      logger.log_error('Unhandled Exception', l_scope, null, l_params);
end toggle_crumb_done;




/**
 * Will use apex_application.g_x01 as a parameter and it is meant to be called
 * form AJAX and returns {success:true,crumbEmpty: true or false}
 *
 * @example
 *
 * This is for verify if the CRUMB type is empty
 *
 *
 * @author Angel Flores
 * @created June 21, 2022
 * @param p_entity_type with apex_application.g_x01 as default
 * @return JSON {success:true,crumbEmpty  true or false}
 */
procedure crumb_info( p_entity_type  in tk_crumbs.entity_type%type default null )
is
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'crumb_info';
  l_params logger.tab_param;

  l_exists                    number;
  l_entity_type               tk_crumbs.entity_type%type;
begin

  if p_entity_type is null then
    l_entity_type := apex_application.g_x01;
  else
    l_entity_type := p_entity_type;
  end if;

  select 1
    into l_exists
    from tk_crumbs
   where entity_type = l_entity_type
     and view_user = g_user
   fetch first rows only;

  apex_json.open_object;
  apex_json.write('success',true);
  apex_json.write('crumbEmpty', false);
  apex_json.close_object;
 exception
    when no_data_found then
      apex_json.open_object;
      apex_json.write('success',true);
      apex_json.write('crumbEmpty', true);
      apex_json.close_object;
    when OTHERS then
      json_status(false, sqlerrm);
      logger.log_error('Unhandled Exception', l_scope, null, l_params);
end crumb_info;







begin

  g_user := coalesce(
      sys_context('APEX$SESSION','app_user')
    , regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
    , sys_context('userenv','session_user')
  );

end tk_crumbs_api;
/