create or replace
package tk_crumbs_api
as


g_entity_type  tk_crumbs.entity_type%type;
g_user         tk_recent_views.view_user%type;
-- type t_crumb as tk_crumbs%rowtype;

procedure reset_crumb_stack(
  p_entity_type  in tk_crumbs.entity_type%type
);

function crumb_on_stack(
    p_entity_type  in tk_crumbs.entity_type%type
  , p_entity_id    in tk_crumbs.entity_id%type
)
return tk_crumbs.id%type;

function get_current_stack_entry(p_entity_type  in tk_crumbs.entity_type%type) return tk_crumbs%rowtype;

procedure touch(
    p_entity_type  in tk_crumbs.entity_type%type
  , p_entity_id    in tk_crumbs.entity_id%type
);

function push(
    p_entity_type  in tk_crumbs.entity_type%type
  , p_entity_id    in tk_crumbs.entity_id%type
)
return number;

procedure push(
    p_entity_type  in tk_crumbs.entity_type%type
  , p_entity_id    in tk_crumbs.entity_id%type
);
procedure push;

function pop(
     p_entity_type in tk_crumbs.entity_type%type
)
return tk_crumbs.id%type;

procedure remove_crumb(p_id  in tk_crumbs.id%type);
procedure remove_crumb;

procedure toggle_crumb_done(p_id  in tk_crumbs.id%type);
procedure toggle_crumb_done;

procedure crumb_info( p_entity_type  in tk_crumbs.entity_type%type default null );

end tk_crumbs_api;
/