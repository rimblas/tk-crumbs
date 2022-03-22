PRO .. tk_crumbs

drop table tk_crumbs cascade constraints purge;

-- Keep table names under 24 characters
--           1234567890123456789012345
create table tk_crumbs (
    id              number        generated always as identity (start with 1) primary key not null
  , view_user       varchar2(60)  not null
  , entity_type     varchar2(20)  not null
  , entity_id       number        not null
  , seq_id          number        not null
  , active_ind      varchar2(1)   not null
  , current_flag    varchar2(1)
  , completed_flag  varchar2(1)
  , created_by      varchar2(60)  default 
coalesce(
    sys_context('APEX$SESSION','app_user')
  , regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
  , sys_context('userenv','session_user')
) not null
  , created_on      date         default sysdate not null
  , last_updated_by varchar2(60)
  , last_updated_on date
  , constraint tk_crumbs_ck_active
      check (active_ind in ('Y', 'N'))
  , constraint tk_crumbs_ck_current
      check (current_flag = 'Y')
  , constraint tk_crumbs_ck_current
      check (completed_flag = 'Y')
)
enable primary key using index
/

create unique index tk_crumbs_u01 on tk_crumbs(view_user, entity_type, entity_id);

comment on table tk_crumbs is 'List crumbs';

comment on column tk_crumbs.id is 'Primary Key ID';
comment on column tk_crumbs.view_user is 'Unique order/id of a crumb type for a user';
comment on column tk_crumbs.seq_id is 'Order/id of a crumb type for a user';
comment on column tk_crumbs.active_ind is 'Is the entity enabled Y/N?';
comment on column tk_crumbs.current_flag is 'Is the entity current Y/null? Only one current allowed';
comment on column tk_crumbs.completed_flag is 'Is the entity completed Y/null? Used when the crumb is an actionable item';
comment on column tk_crumbs.created_by is 'User that created this record';
comment on column tk_crumbs.created_on is 'Date the record was first created';
comment on column tk_crumbs.last_updated_by is 'User that last modified this record';
comment on column tk_crumbs.last_updated_on is 'Date the record was last modified';


--------------------------------------------------------
--                        123456789012345678901234567890
create or replace trigger tk_crumbs_u_trg
before update
on tk_crumbs
referencing old as old new as new
for each row
begin
  :new.last_updated_on := sysdate;
  :new.last_updated_by := coalesce(
                         sys_context('APEX$SESSION','app_user')
                       , regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
                       , sys_context('userenv','session_user')
                     );
end;
/
