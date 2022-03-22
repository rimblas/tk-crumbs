create or replace view tk_crumbs_v
as
select id
     , view_user
     , entity_type
     , entity_id
     , seq_id
     , active_ind
     , current_flag
     , completed_flag
     , created_by
     , created_on
     , last_updated_by
     , last_updated_on
  from tk_crumbs
 where view_user = coalesce(
    sys_context('APEX$SESSION','app_user')
  , regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
  , sys_context('userenv','session_user')
)
/
