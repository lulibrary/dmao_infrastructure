

-- Postgres DDL for DMAOnline database, v0.2

-------------------------------------------------------------------
-------------------------------------------------------------------
drop table if exists map_inst_ds cascade;
drop table if exists map_funder_project cascade;
drop table if exists map_project_ds cascade;
drop table if exists map_project_pub cascade;
drop table if exists map_dept_pub cascade;
drop table if exists map_dept_ds cascade;
drop table if exists map_pub_ds cascade;
drop table if exists map_funder_pub cascade;
drop table if exists map_funder_ds cascade;
drop table if exists users cascade;
drop table if exists project_storage_requirement cascade;
drop table if exists project cascade;
drop table if exists dmp cascade;
drop table if exists publication cascade;
drop table if exists dataset_accesses;
drop table if exists dataset cascade;
drop table if exists inst_storage_costs cascade;
drop table if exists inst_storage_platforms cascade;
drop table if exists department cascade;
drop table if exists funder_dmp_states cascade;
drop table if exists funder cascade;
drop table if exists faculty cascade;
drop table if exists institution cascade;


-------------------------------------------------------------------
-------------------------------------------------------------------
-- Type declarations
drop domain if exists inst_id_t cascade;
create domain inst_id_t varchar(256);
drop domain if exists inst_storage_platform_id_t cascade;
create domain inst_storage_platform_id_t varchar(256);
drop domain if exists funder_id_t;
create domain funder_id_t varchar(256);

-------------------------------------------------------------------
-------------------------------------------------------------------
create or replace function encrypt_password(bytea) returns text as $$
  select encode(digest($1, 'sha224'), 'hex' )
$$ language sql strict immutable;

-- generate an API key to be used to access an institution's data
create or replace function gen_api_key() returns text as $$
  select encode
    (
      digest(crypt(cast(gen_random_bytes(32) as text), 'bf')
        || to_char(current_timestamp, 'YYYYMMDDHHMMSSUS'),
      'sha224'),
      'hex'
    )
$$ language sql strict immutable;


-------------------------------------------------------------------
-------------------------------------------------------------------
create table institution (
  inst_id inst_id_t unique not null primary key,
  name varchar(256) not null,
  contact varchar(256),
  contact_email varchar(256),
  contact_phone varchar(256),
  cris_sys varchar(1024),
  pub_sys varchar(1024),
  dataset_sys varchar(1024),
  archive_sys varchar(1024),
  currency varchar(3),
  currency_symbol varchar(32),
  url varchar(2048),
  description varchar,
  api_key varchar(128),
  datacite_id varchar(64),
  load_date timestamp,
  mod_date timestamp
);
comment on table institution is 'Describes an institution.';
comment on column institution.cris_sys is
  'A description of the CRIS
  system in use at this institution, e.g. ''Pure''.';
comment on column institution.pub_sys is
  'A description of the publication repository
  system in use at this institution e.g. ''Eprints''.';

-- this trigger function is used throughout to set load and
-- modification dates
create or replace function load_date_action() returns trigger
as $$
begin
  if TG_OP = 'INSERT' then
    new.load_date = now();
  end if;
  if TG_OP = 'UPDATE' then
    new.mod_date = now();
  end if;
  return new;
end;
$$ language plpgsql;

create trigger action_date before insert or update on institution
  for each row execute procedure load_date_action();


-------------------------------------------------------------------
-------------------------------------------------------------------
create table faculty (
  faculty_id serial primary key,
  inst_id inst_id_t references institution(inst_id)
    on delete cascade on update cascade not null,
  name varchar(256) not null,
  abbreviation varchar(64),
  inst_local_id varchar(64),
  url varchar(2048),
  description varchar,
  load_date timestamp,
  mod_date timestamp,
  unique (inst_id, inst_local_id, name)
);
comment on table faculty is
  'Describes a faculty, the combination of the
  institution id and the faculty name must be unique.';

create trigger action_date before insert or update on faculty
  for each row execute procedure load_date_action();


-------------------------------------------------------------------
-------------------------------------------------------------------
create table department (
  department_id serial primary key,
  inst_id inst_id_t references institution(inst_id)
    on delete cascade on update cascade not null,
  faculty_id integer references faculty(faculty_id)
    on delete cascade on update cascade not null,
  name varchar(1024) not null,
  abbreviation varchar(64),
  inst_local_id varchar(64),
  url varchar(2048),
  description varchar,
  load_date timestamp,
  mod_date timestamp,
  unique (inst_id, faculty_id, name)
);
comment on table department is
  'Describes a department within a faculty. The combination
  of institution id, faculty id and name must be unique.';

create trigger action_date before insert or update on department
  for each row execute procedure load_date_action();


-------------------------------------------------------------------
-------------------------------------------------------------------
create table funder (
  funder_id funder_id_t unique not null primary key,
  name varchar(2048) not null,
  inst_alt_name varchar(2048),
  inst_local_id varchar(64),
  is_rcuk_funder boolean default false,
  inst_id inst_id_t references institution(inst_id)
    on delete cascade on update cascade not null,
  url varchar(2048),
  load_date timestamp,
  mod_date timestamp
);
comment on table funder is 'Describes a funding body.';

create trigger action_date before insert or update on funder
  for each row execute procedure load_date_action();


-------------------------------------------------------------------
-------------------------------------------------------------------
create table funder_dmp_states (
  dmp_state_id serial primary key,
  funder_id funder_id_t references funder(funder_id)
    on delete cascade on update cascade,
  funder_state_code varchar(256) not null,
  funder_state_name varchar(1024),
  load_date timestamp,
  mod_date timestamp
);
create index on funder_dmp_states(funder_id);
create index on funder_dmp_states(funder_state_code);
create index on funder_dmp_states(funder_state_name);
comment on table funder_dmp_states is
  'Describes the states that a funder specifies for DMPs';

create trigger action_date before insert or update on funder_dmp_states
  for each row execute procedure load_date_action();


-------------------------------------------------------------------
-------------------------------------------------------------------
-- DMP - Data Management Plan
create table dmp (
  dmp_id serial primary key,
  dmp_source_system varchar(256),
  dmp_ss_pid varchar(256),
  dmp_state integer references funder_dmp_states(dmp_state_id)
    on delete cascade on update cascade,
  dmp_status varchar(50),
  author_orcid varchar(256),
  load_date timestamp,
  mod_date timestamp
  check (dmp_status in ('verified', 'completed', 'in progress',
                       'new', 'none'))
);
create index on dmp(dmp_source_system, dmp_ss_pid);
comment on table dmp is 'Describes data management plans';
comment on column dmp.dmp_source_system is
  'Describes the source system for the data management
  plan, e.g. ''DMPOnline''.';
comment on column dmp.dmp_ss_pid is
  'The DMP source system persistent identifier for this data management
  plan.';
comment on column dmp.dmp_state is
  'Some funders require multiple iterations of data management plan
  development, this integer field is used to identify the state.';
comment on column dmp.dmp_status is
  'The DMP status, can be one of
  ''none'', ''new'', ''in progress'', ''completed'', ''verified''.';

create trigger action_date before insert or update on dmp
  for each row execute procedure load_date_action();


-------------------------------------------------------------------
-------------------------------------------------------------------
create table inst_storage_platforms (
  inst_id inst_id_t references institution(inst_id)
    on delete cascade on update cascade,
  inst_storage_platform_id inst_storage_platform_id_t,
  inst_notes varchar(1024),
  inst_api_url varchar(2048),
  load_date timestamp,
  mod_date timestamp,
  primary key(inst_id, inst_storage_platform_id)
);
create index on inst_storage_platforms(inst_id);
create index on inst_storage_platforms(inst_storage_platform_id);
comment on table inst_storage_platforms is 'Describes the institution''s '
  'storage management platforms';

create table inst_storage_costs (
  sc_id serial primary key,
  inst_id inst_id_t references institution(inst_id)
    on delete cascade on update cascade,
  inst_storage_platform_id inst_storage_platform_id_t,
  cost_per_tb_pa numeric
    check (cost_per_tb_pa >= 0) default 0,
  applicable_dates daterange,
  load_date timestamp,
  mod_date timestamp,
  foreign key(inst_id, inst_storage_platform_id)
    references inst_storage_platforms(inst_id, inst_storage_platform_id)
      on delete cascade on update cascade
);
create index on inst_storage_costs(inst_id);
create index on inst_storage_costs(inst_storage_platform_id);
create index on inst_storage_costs(inst_id, inst_storage_platform_id);
comment on table inst_storage_costs
  is 'Describes storage costs for institutional storage platforms';

create trigger action_date before insert or update on inst_storage_costs
  for each row execute procedure load_date_action();


-------------------------------------------------------------------
-------------------------------------------------------------------
create table project (
  project_id serial primary key,
  project_name varchar(2048),
  project_acronym varchar(512),
  inst_local_id varchar(64),
  inst_project_status varchar(128),
  inst_project_classification varchar(512),
  inst_project_type varchar(128),
  description varchar,
  funder_project_code varchar(256),
  is_awarded boolean default false,
  inst_id inst_id_t references institution(inst_id)
    on delete cascade on update cascade,
  institution_project_code varchar(256),
  lead_faculty_id integer references faculty(faculty_id)
    on delete cascade on update cascade,
  lead_department_id integer references department(department_id)
    on delete cascade on update cascade,
  has_dmp boolean default null,
  has_dmp_been_reviewed varchar(50),
  dmp_id integer references dmp(dmp_id)
    on delete cascade on update cascade,
  project_awarded date,
  project_date_range daterange,
  project_start date,
  project_end date,
  inst_url varchar(2048),
  load_date timestamp,
  mod_date timestamp,
  check (has_dmp_been_reviewed in ('yes', 'no', 'unknown')),
  unique(inst_id, inst_local_id)
);
comment on table project is 'Describes an institutions projects';
comment on column project.funder_project_code is
  'A code assigned to the project by the funding body, it may be null
  if the funding application is in process.';
comment on column project.is_awarded is
  'Is ''true'' if funding has been successfully applied
  for, ''false'' otherwise';
comment on column project.has_dmp is
  'Is ''true'' if a DMP exists, ''false'' otherwise.';
comment on column project.has_dmp_been_reviewed is
  'Is ''true'' if a DMP exists and has been reviewed, ''false'' '
  'otherwise.';

create or replace function project_date_update() returns trigger
as $$
begin
    new.project_start = lower(new.project_date_range);
    new.project_end = upper(new.project_date_range);
    return new;
end;
$$ language plpgsql;

create trigger project_trigger before insert or update on project
  for each row execute procedure project_date_update();

create trigger action_date before insert or update on project
  for each row execute procedure load_date_action();


-------------------------------------------------------------------
-------------------------------------------------------------------
create table project_storage_requirement (
  inst_id inst_id_t not null,
  inst_storage_platform_id inst_storage_platform_id_t,
  project_id integer references project(project_id)
    on delete cascade on update cascade not null,
  expected_storage numeric not null
    check (expected_storage >= 0) default 0,
  foreign key (inst_id, inst_storage_platform_id)
    references inst_storage_platforms(inst_id, inst_storage_platform_id)
    on delete restrict on update cascade,
  keep_until date,
  load_date timestamp,
  mod_date timestamp,
  unique(inst_id, inst_storage_platform_id, project_id)
);
create index on project_storage_requirement(inst_id,
                                            inst_storage_platform_id);
create index on project_storage_requirement(inst_id);
create index on project_storage_requirement(project_id);
comment on column project_storage_requirement.expected_storage is
'The amount of storage in GB this project is expecting to need to '
'use on storage platform <sc_id>.';

create trigger action_date before insert or update on
  project_storage_requirement
  for each row execute procedure load_date_action();


-------------------------------------------------------------------
-------------------------------------------------------------------
create table users (
  username varchar(64),
  name varchar(256),
  inst_id inst_id_t references institution(inst_id)
    on delete cascade on update cascade not null,
  email varchar(1024),
  phone varchar(128),
  passwd varchar(128),
  load_date timestamp,
  mod_date timestamp,
  unique(username, inst_id)
);


create trigger action_date before insert or update on users
  for each row execute procedure load_date_action();


-------------------------------------------------------------------
-------------------------------------------------------------------
create table dataset (
  dataset_id serial primary key,
  inst_id inst_id_t references institution(inst_id)
    on delete cascade on update cascade,
  project_id integer references project(project_id)
    on delete cascade on update cascade,
  dataset_local_inst_id varchar(1024),
  dataset_pid varchar(256),
  dataset_link varchar(8192),
  dataset_filename varchar,
  dataset_size numeric default 0,
  dataset_name varchar,
  dataset_format varchar,
  dataset_notes varchar,
  dataset_create_date date,
  repository_pid varchar(2048),
  inst_archive_status varchar(256),
  archive_pid varchar(2048),
  storage_location varchar(50),
  lead_faculty_id integer references faculty(faculty_id)
    on delete cascade on update cascade,
  lead_department_id integer references department(department_id)
    on delete cascade on update cascade,
  load_date timestamp,
  mod_date timestamp,
  check (storage_location in ('internal', 'external')),
  check (inst_archive_status in ('archived', 'not_archived', 'unknown')),
  unique(inst_id, dataset_local_inst_id)
);
comment on table dataset is 'Describes datasets';
comment on column dataset.dataset_pid is
  'The persistent id for the dataset';
comment on column dataset.dataset_link is
  'The persistent url for the dataset';
comment on column dataset.dataset_size is
  'The current size of the dataset in GB for the dataset';
comment on column dataset.storage_location is
  'Can be either ''internal'' or ''external'' to the institution.';

create trigger action_date before insert or update on dataset
  for each row execute procedure load_date_action();


-------------------------------------------------------------------
-------------------------------------------------------------------
create table dataset_accesses (
  dataset_id integer references dataset(dataset_id)
    on delete cascade on update cascade,
  access_type varchar(64),
  access_date date,
  counter integer,
  load_date timestamp,
  mod_date timestamp,
  check (access_type in ('metadata', 'data_download'))
);
create index on dataset_accesses(dataset_id);
create index on dataset_accesses(access_type);
create index on dataset_accesses(access_date);

create trigger action_date before insert or update on dataset_accesses
  for each row execute procedure load_date_action();


-------------------------------------------------------------------
-------------------------------------------------------------------
create table publication (
  publication_id serial primary key,
  inst_id inst_id_t references institution(inst_id)
    on delete cascade on update cascade,
  project_id integer references project(project_id)
    on delete cascade on update cascade,
  cris_id varchar(256),
  repo_id varchar(256),
  publication_pid varchar(256),
  funder_project_code varchar(256),
  lead_faculty_id integer references faculty(faculty_id)
    on delete cascade on update cascade,
  lead_department_id integer references department(department_id)
    on delete cascade on update cascade,
  publication_date date,
  data_access_statement boolean default false,
  data_access_statement_notes varchar(1024),
  rcuk_funder_compliant varchar(50) default 'n'
    check (rcuk_funder_compliant in ('y', 'n', 'partial')),
  other_funder_compliant varchar(50) default 'n'
    check (other_funder_compliant in ('y', 'n', 'partial')),
  inst_url varchar(2048),
  inst_pub_type varchar(1024),
  inst_pub_status varchar(512),
  inst_pub_year int,
  inst_pub_month int,
  inst_pub_day int,
  inst_pub_title varchar,
  inst_pub_abstract varchar,
  load_date timestamp,
  mod_date timestamp,
  unique(inst_id, cris_id)
);
comment on table publication is 'Describes publications';
comment on column publication.project_id is
  'The institution project identifier';
comment on column publication.cris_id is
  'The institution CRIS identifier';
comment on column publication.cris_id is
  'The institution repository identifier';
comment on column publication.repo_id is
  'The institution repository identifier';
comment on column publication.publication_pid is
  'The persistent identifier, e.g. a DOI, for the publication';

create trigger action_date before insert or update on publication
  for each row execute procedure load_date_action();


-------------------------------------------------------------------
-------------------------------------------------------------------
create table map_pub_ds (
  publication_id integer references publication(publication_id)
    on delete cascade on update cascade not null,
  dataset_id integer references dataset(dataset_id)
    on delete cascade on update cascade not null
);
comment on table map_pub_ds is 'Maps publications to datasets.';

create index on map_pub_ds(publication_id);
create index on map_pub_ds(dataset_id);


-------------------------------------------------------------------
-------------------------------------------------------------------
create table map_dept_pub (
  department_id integer references department(department_id)
    on delete cascade on update cascade not null,
  publication_id integer references publication(publication_id)
    on delete cascade on update cascade not null
);
comment on table map_dept_pub is 'Maps departments to publications.';

create index on map_dept_pub(department_id);
create index on map_dept_pub(publication_id);


-------------------------------------------------------------------
-------------------------------------------------------------------
create table map_dept_ds (
  department_id integer references department(department_id)
    on delete cascade on update cascade not null,
  dataset_id integer references dataset(dataset_id)
    on delete cascade on update cascade not null
);
comment on table map_dept_ds is 'Maps departments to datasets.';

create index on map_dept_ds(department_id);
create index on map_dept_ds(dataset_id);


-------------------------------------------------------------------
-------------------------------------------------------------------
create table map_funder_pub (
  funder_id funder_id_t references funder(funder_id)
    on delete cascade on update cascade not null,
  publication_id integer references publication(publication_id)
    on delete cascade on update cascade not null
);
comment on table map_funder_pub is 'Maps funders to publications.';

create index on map_funder_pub(funder_id);
create index on map_funder_pub(publication_id);


-------------------------------------------------------------------
-------------------------------------------------------------------
create table map_funder_ds (
  funder_id funder_id_t references funder(funder_id)
    on delete cascade on update cascade not null,
  dataset_id integer references dataset(dataset_id)
    on delete cascade on update cascade not null
);
comment on table map_funder_ds is 'Maps funders to datasets.';

create index on map_funder_ds(funder_id);
create index on map_funder_ds(dataset_id);



-------------------------------------------------------------------
-------------------------------------------------------------------
create table map_funder_project (
  funder_id funder_id_t references funder(funder_id)
    on delete cascade on update cascade not null,
  project_id integer references project(project_id)
    on delete cascade on update cascade not null
);
comment on table map_funder_project is 'Maps funders to projects.';

create index on map_funder_project(funder_id);
create index on map_funder_project(project_id);


-------------------------------------------------------------------
-------------------------------------------------------------------
create table map_project_ds (
  project_id integer references project(project_id)
    on delete cascade on update cascade not null,
  dataset_id integer references dataset(dataset_id)
    on delete cascade on update cascade not null
);
comment on table map_project_ds is 'Maps projects to datasets.';

create index on map_project_ds(project_id);
create index on map_project_ds(dataset_id);



-------------------------------------------------------------------
-------------------------------------------------------------------
create table map_project_pub (
  project_id integer references project(project_id)
    on delete cascade on update cascade not null,
  publication_id integer references publication(publication_id)
    on delete cascade on update cascade not null
);
comment on table map_project_pub is 'Maps projects to publications.';

create index on map_project_pub(project_id);
create index on map_project_pub(publication_id);


-------------------------------------------------------------------
-------------------------------------------------------------------
create table map_inst_ds (
  inst_id inst_id_t references institution(inst_id)
    on delete cascade on update cascade not null,
  dataset_id integer references dataset(dataset_id)
    on delete cascade on update cascade not null
);
comment on table map_inst_ds is 'Maps institutions and datasets.';

create index on map_inst_ds(inst_id);
create index on map_inst_ds(dataset_id);


-------------------------------------------------------------------
-------------------------------------------------------------------
create or replace view map_dataset_faculty as
  select
    d.dataset_id,
    f.faculty_id
  from
    dataset d
  left outer join
    faculty f
  on
    d.lead_faculty_id = f.faculty_id;


-------------------------------------------------------------------
-------------------------------------------------------------------
create or replace view project_expected_storage as
  select
    psr.inst_id,
    psr.inst_storage_platform_id,
    psr.project_id,
    psr.expected_storage,
    isp.inst_notes,
    p.project_date_range,
    psr.keep_until
  from
    project_storage_requirement psr
  join
    project p
  on
    (psr.project_id = p.project_id)
  join
    inst_storage_platforms isp
  on
    (psr.inst_id, psr.inst_storage_platform_id)
    =
    (isp.inst_id, isp.inst_storage_platform_id)
--   where psr.project_id = 10
  order by
    p.inst_id asc,
    p.project_id asc
;


-------------------------------------------------------------------
-------------------------------------------------------------------
create or replace function days_in_date_range(daterange)
  returns integer as
$$
  select upper($1) - lower($1);
$$ language sql;

-------------------------------------------------------------------
-------------------------------------------------------------------
create or replace view project_storage_costs_breakdown as
  select
    pes.inst_id,
    pes.project_id,
    pes.inst_storage_platform_id,
    pes.inst_notes,
    pes.project_date_range,
    pes.expected_storage,
    sc.applicable_dates sc_applicable_dates,
    cost_per_tb_pa sp_cost_per_tb_pa,
    cost_per_tb_pa/365, 5 sp_cost_per_tb_pd,
    (
      pes.expected_storage/1024 *
      cost_per_tb_pa/365 *
      days_in_date_range(pes.project_date_range)
    ) sp_cost_over_project
  from
    project_expected_storage pes
  join
    inst_storage_costs sc
  on
    (
      (pes.inst_id, pes.inst_storage_platform_id)
      =
      (sc.inst_id, sc.inst_storage_platform_id)
    )
  order by
    pes.inst_id asc,
    pes.project_id asc,
    pes.inst_storage_platform_id,
    sc.applicable_dates asc
;

create or replace view project_storage_costs_over_sp as
  select
    inst_id,
    project_id,
    inst_storage_platform_id,
    sum(sp_cost_over_project) sp_cost
  from
    project_storage_costs_breakdown
  group by
    inst_id, project_id, inst_storage_platform_id
  order by project_id asc
;

create or replace view expected_project_storage_costs as
  select
    inst_id,
    project_id,
    sum(sp_cost) eps_cost
  from
    project_storage_costs_over_sp
  group by
    inst_id, project_id
  order by
    project_id asc
;


-- -------------------------------------------------------------------
-- -------------------------------------------------------------------
-- create or replace view project_storage_costs_intermediate as
--   select
--     pscb.inst_id,
--     pscb.project_id,
--     pscb.inst_storage_platform_id,
--     pscb.applicable_dates * pscb.project_date_range project_storage_dates,
--     sum(pscb.storage_cost_pa) storage_cost_pa
--   from
--     project_storage_costs_breakdown pscb
--   join
--     project p
--   on
--     (pscb.project_id = p.project_id)
--   where
--     not isempty(pscb.applicable_dates * pscb.project_date_range)
--   group by
--     pscb.inst_id,
--     pscb.project_id,
--     pscb.inst_storage_platform_id,
--     project_storage_dates
--   order by
--     pscb.inst_id,
--     pscb.project_id
-- ;
--
--
-- ---------------------------------------------------------------------
-- ---------------------------------------------------------------------
-- create or replace function project_costs_at_date
--   (
--     i_id inst_id_t,
--     p_id int,
--     d date
--   )
--   returns table (
--     inst_storage_platform_id inst_storage_platform_id_t,
--     cost_pa numeric
--   )
-- as
-- $$
--   select
--     inst_storage_platform_id,
--     storage_cost_pa
--   from
--     project_storage_costs_intermediate
--   where
--     inst_id = i_id
--   and
--     project_id = p_id
--   and
--     project_storage_dates @> d
-- $$
-- language sql strict immutable;
--
--
-- ---------------------------------------------------------------------
-- ---------------------------------------------------------------------
-- create or replace function all_project_costs_at_date
--   (
--     i_id inst_id_t,
--     d date
--   )
--   returns table(
--     project_id int,
--     inst_storage_platform_id inst_storage_platform_id_t,
--     cost_pa numeric
--   )
-- as
-- $$
--   select
--     project_id,
--     inst_storage_platform_id,
--     storage_cost_pa
--   from
--     project_storage_costs_intermediate
--   where
--     inst_id = i_id
--   and
--     project_storage_dates @> d
-- $$
-- language sql strict immutable;
--
--
-- ---------------------------------------------------------------------
-- ---------------------------------------------------------------------
-- create or replace function project_costs_during_daterange
--   (
--     i_id inst_id_t,
--     p_id int,
--     d daterange
--   )
--   returns table(
--     project_storage_dates daterange,
--     inst_storage_platform_id inst_storage_platform_id_t,
--     cost_pa numeric
--   )
-- as
-- $$
--   select
--     project_storage_dates,
--     inst_storage_platform_id,
--     storage_cost_pa
--   from
--     project_storage_costs_intermediate
--   where
--     inst_id = i_id
--   and
--     project_id = p_id
--   and
--     project_storage_dates && d
-- $$
-- language sql strict immutable;
--
--
-- ---------------------------------------------------------------------
-- ---------------------------------------------------------------------
-- create or replace function expand_project_costs_during_daterange
--   (
--     i_id inst_id_t,
--     p_id int,
--     dr daterange
--   )
--   returns table (
--     day date,
--     isp_id inst_storage_platform_id_t,
--     cost_pa numeric
--   )
-- as
-- $$
--   select
--     d::date as day,
--     v.inst_storage_platform_id as isp_id,
--     v.cost_pa as cost_pa
--   from
--     generate_series(lower(dr)::date, upper(dr)::date, '1 day'::interval) d,
--     project_costs_at_date(i_id, p_id, d::date) v
--   order by
--     day, isp_id asc
-- $$
-- language sql strict immutable;
--
--
-- ---------------------------------------------------------------------
-- ---------------------------------------------------------------------
-- create or replace function aggregate_project_costs_during_daterange
--   (
--     i_id inst_id_t,
--     p_id int,
--     dr daterange
--   )
--   returns table (
--     day date,
--     cost_pa numeric
--   )
-- as
-- $$
--   select
--     d::date as day,
--     sum(v.cost_pa) as cost_pa
--   from
--     generate_series(lower(dr)::date, upper(dr)::date, '1 day'::interval) d,
--     project_costs_at_date(i_id, p_id, d::date) v
--   group by day
--   order by day asc
-- $$
-- language sql strict immutable;
--
--
-- ---------------------------------------------------------------------
-- ---------------------------------------------------------------------
-- create or replace function all_project_costs_during_daterange
--   (
--     i_id inst_id_t,
--     d daterange
--   )
--   returns table(
--     p_id int,
--     project_storage_dates daterange,
--     inst_storage_platform_id inst_storage_platform_id_t,
--     cost numeric
--   )
-- as
-- $$
--   select
--     project_id,
--     project_storage_dates,
--     inst_storage_platform_id,
--     storage_cost_pa
--   from
--     project_storage_costs_intermediate
--   where
--     inst_id = i_id
--   and
--     project_storage_dates && d
-- $$
-- language sql strict immutable;


---------------------------------------------------------------------
---------------------------------------------------------------------
create or replace view project_status as
  select
    project_id,
    (
      case when
        upper(project.project_date_range) > now()
        then
          'active'
        else
          'inactive'
      end
    ) status
  from
    project
;


---------------------------------------------------------------------
---------------------------------------------------------------------
create or replace view project_dmps_view as
  select
    p.*,
    f.abbreviation lead_faculty_abbrev,
    f.name         lead_faculty_name,
    d.abbreviation lead_dept_abbrev,
    d.name         lead_dept_name
  from project p
    join
    faculty f
      on
        (p.lead_faculty_id = f.faculty_id)
    join
    department d
      on
        (p.lead_department_id = d.department_id);

drop table if exists project_dmps_view_modifiables;
create table project_dmps_view_modifiables (
  c_name varchar(128),
  c_vals varchar(128)
);

insert into project_dmps_view_modifiables values
  ('has_dmp', 'true|false'),
  ('has_dmp_been_reviewed', 'yes|no|unknown'),
  ('dmp_id', 'integer')
;

create or replace function project_dmps_view_update()
  returns trigger
language plpgsql
as $$
begin
  if TG_OP = 'UPDATE'
  then
    update project set
      has_dmp = NEW.has_dmp,
      has_dmp_been_reviewed = NEW.has_dmp_been_reviewed,
      dmp_id = NEW.dmp_id
    where project_id = OLD.project_id;
  end if;
  return NEW;
end;
$$;

create trigger project_dmps_view_update_trigger
instead of update on
  project_dmps_view
for each row execute procedure project_dmps_view_update();


---------------------------------------------------------------------
---------------------------------------------------------------------
create or replace view storage_view as
  select
    p.inst_id,
    p.project_id,
    p.project_awarded,
    p.project_start,
    p.project_end,
    p.project_name,
    p.lead_faculty_id,
    p.lead_department_id,
    pes.expected_storage,
    pscosp.sp_cost expected_storage_cost,
    pes.inst_storage_platform_id,
    pes.inst_notes,
    d.dataset_id,
    d.dataset_pid,
    d.dataset_size
  from
    project p
  left outer join
    dataset d
  on
    (p.project_id = d.project_id)
  left outer join
    project_expected_storage pes
  on
    (p.project_id = pes.project_id)
  left outer join
    project_storage_costs_over_sp pscosp
  on
    (
      p.project_id = pscosp.project_id
      and
      pes.inst_storage_platform_id = pscosp.inst_storage_platform_id
    )
  order by
    p.project_id asc
;

drop table if exists storage_view_modifiables;
create table storage_view_modifiables (
  c_name varchar(128),
  c_vals varchar(128)
);

insert into storage_view_modifiables values
  ('expected_storage', 'numeric'),
  ('inst_storage_platform_id', 'string')
;

create or replace view storage_ispi_list as
  select inst_id, inst_storage_platform_id ispi, inst_notes ispn
  from inst_storage_platforms;
--   group by inst_id, inst_storage_platform_id;

create or replace function storage_view_update()
  returns trigger
language plpgsql
as $$
begin
  if (TG_OP = 'UPDATE') then
    update project_storage_requirement set
      expected_storage = NEW.expected_storage,
      inst_storage_platform_id = NEW.inst_storage_platform_id
    where
      project_id = OLD.project_id
    and
      inst_storage_platform_id = OLD.inst_storage_platform_id;
    return NEW;
  elseif (TG_OP = 'DELETE') then
    delete from project_storage_requirement
      where
        inst_storage_platform_id = OLD.inst_storage_platform_id
      and
        project_id = OLD.project_id;
    if not found then return null; end if;
    return OLD;
  end if;
end;
$$;

create trigger storage_view_update_trigger
instead of update or delete on
  storage_view
for each row execute procedure storage_view_update();


---------------------------------------------------------------------
---------------------------------------------------------------------
create or replace view datasets_view as
  select
    f.funder_id full_funder_id,
    regexp_replace(f.funder_id, '^.*:', '') funder_id,
    f.name funder_name,
    d.*,
    fac.abbreviation lead_faculty_abbrev,
    fac.name lead_faculty_name,
    dept.abbreviation lead_dept_abbrev,
    dept.name lead_dept_name,
    p.project_awarded,
    p.project_start,
    p.project_end,
    p.project_name,
    p.project_date_range
  from
    dataset d
  left outer join
    map_funder_ds fdm
  on
    (d.dataset_id = fdm.dataset_id)
  left outer join
    funder f
  on
    (fdm.funder_id = f.funder_id)
  left outer join
    faculty fac
  on
    (d.lead_faculty_id = fac.faculty_id)
  left outer join
    department dept
  on
    (d.lead_department_id = dept.department_id)
  left outer join
    project p
  on
    (d.project_id = p.project_id)
  order by
    d.dataset_id asc
;


---------------------------------------------------------------------
---------------------------------------------------------------------
create or replace view dmp_status_view as
  select
    p.*,
    mfp.funder_id full_funder_id,
    regexp_replace(mfp.funder_id, '^.*:', '') funder_id,
    dmp.dmp_source_system,
    dmp.dmp_ss_pid dmp_source_system_id,
    dmp.dmp_state,
    dmp.dmp_status,
    dmp.author_orcid,
    f.name funder_name,
    fds.funder_state_code,
    fds.funder_state_name
  from
    project p
  left outer join
    map_funder_project mfp
    on
      (p.project_id = mfp.project_id)
    left outer join
      dmp
    on
      (p.dmp_id = dmp.dmp_id)
    left outer join
      funder_dmp_states fds
    on
      (dmp.dmp_state = fds.dmp_state_id)
    left outer join
      funder f
    on
      (fds.funder_id = f.funder_id)
;


---------------------------------------------------------------------
---------------------------------------------------------------------
create or replace view rcuk_as_view as
  select
    pub.*,
    mfp.funder_id full_funder_id,
    regexp_replace(mfp.funder_id, '^.*:', '') funder_id,
    f.name funder_name,
    proj.project_name,
    proj.project_awarded,
    proj.project_start,
    proj.project_end
  from
    publication pub
  join
    map_funder_pub mfp
  on
    (pub.publication_id = mfp.publication_id)
  join
    funder f
  on
    (f.funder_id = mfp.funder_id)
  left outer join
    project proj
  on
    (pub.project_id = proj.project_id)
  where
    mfp.funder_id in (
      select funder_id
      from funder where is_rcuk_funder is true
    )
;

