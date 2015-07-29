

-- Postgres DDL for DMAOnline database, v0.2

drop table if exists inst_ds_map cascade;
drop table if exists funder_project_map cascade;
drop table if exists project_ds_map cascade;
drop table if exists project_pub_map cascade;
drop table if exists dept_pub_map cascade;
drop table if exists dept_ds_map cascade;
drop table if exists pub_ds_map cascade;
drop table if exists funder_pub_map cascade;
drop table if exists funder_ds_map cascade;
drop table if exists users cascade;
drop table if exists project cascade;
drop table if exists dmp cascade;
drop table if exists publication cascade;
drop table if exists dataset_accesses;
drop table if exists dataset cascade;
drop table if exists storage_costs cascade;
drop table if exists department cascade;
drop table if exists funder_dmp_states cascade;
drop table if exists funder cascade;
drop table if exists faculty cascade;
drop table if exists institution cascade;


-------------------------------------------------------------------
-------------------------------------------------------------------
create or replace function sha512(bytea) returns text as $$
  select encode(digest($1, 'sha512'), 'hex')
$$ language sql strict immutable;

-------------------------------------------------------------------
-------------------------------------------------------------------
create table institution (
  inst_id varchar(256) unique not null primary key,
  name varchar(256) not null,
  contact varchar(256) not null,
  contact_email varchar(256),
  contact_phone varchar(256),
  cris_sys varchar(1024),
  pub_sys varchar(1024),
  dataset_sys varchar(1024),
  archive_sys varchar(1024),
  currency varchar(3),
  currency_symbol varchar(32)
);
comment on table institution is 'Describes an institution.';
comment on column institution.cris_sys is
  'A description of the CRIS
  system in use at this institution, e.g. ''Pure''.';
comment on column institution.pub_sys is
  'A description of the publication repository
  system in use at this institution e.g. ''Eprints''.';



-------------------------------------------------------------------
-------------------------------------------------------------------
create table faculty (
  faculty_id serial primary key,
  inst_id varchar(256) references institution(inst_id)
    on delete cascade on update cascade not null,
  name varchar(256) not null,
  abbreviation varchar(64),
  unique (inst_id, name)
);
comment on table faculty is
  'Describes a faculty, the combination of the
  institution id and the faculty name must be unique.';


-------------------------------------------------------------------
-------------------------------------------------------------------
create table department (
  department_id serial primary key,
  inst_id varchar(256) references institution(inst_id)
    on delete cascade on update cascade not null,
  faculty_id integer references faculty(faculty_id)
    on delete cascade on update cascade not null,
  name varchar(256) not null,
  abbreviation varchar(64) not null,
  unique (inst_id, faculty_id, name)
);
comment on table department is
  'Describes a department within a faculty. The combination
  of institution id, faculty id and name must be unique.';


-------------------------------------------------------------------
-------------------------------------------------------------------
create table funder (
  funder_id varchar(256) unique not null primary key,
  name varchar(256) not null
);
comment on table funder is 'Describes a funding body.';


-------------------------------------------------------------------
-------------------------------------------------------------------
create table funder_dmp_states (
  dmp_state_id serial primary key,
  funder_id varchar(256) references funder(funder_id)
    on delete cascade on update cascade,
  funder_state_code varchar(256) not null,
  funder_state_name varchar(1024)
);
create index on funder_dmp_states(funder_id);
create index on funder_dmp_states(funder_state_code);
create index on funder_dmp_states(funder_state_name);
comment on table funder_dmp_states is
  'Describes the states that a funder specifies for DMPs';


-------------------------------------------------------------------
-------------------------------------------------------------------
create table dmp (
  dmp_id serial primary key,
  dmp_source_system varchar(256),
  dmp_ss_pid varchar(256),
  dmp_state integer references funder_dmp_states(dmp_state_id)
    on delete cascade on update cascade,
  dmp_status varchar(50),
  author_orcid varchar(256)
  check (dmp_status in ('verified', 'completed', 'in progress',
                       'new', 'none'))
);
create index on dmp(dmp_source_system, dmp_ss_pid);
comment on table dmp is 'Describes data management plans';
comment on column dmp.dmp_source_system is
  'Describes the source system for the data management
  plan, e.g. ''DMPonline''.';
comment on column dmp.dmp_ss_pid is
  'The DMP source system persistent identifier for this data management
  plan.';
comment on column dmp.dmp_state is
  'Some funders require multiple iterations of data management plan
  development, this integer field is used to identify the state.';
comment on column dmp.dmp_status is
  'The DMP status, can be one of
  ''none'', ''new'', ''in progress'', ''completed'', ''verified''.';


-------------------------------------------------------------------
-------------------------------------------------------------------
create table storage_costs (
  sc_id serial primary key,
  inst_id varchar(256) references institution(inst_id)
    on delete cascade on update cascade,
  inst_reference varchar(1024),
  cost_per_tb numeric
);
create index on storage_costs(inst_id);
comment on table storage_costs
  is 'Describes storage costs for institutional storage platforms';


-------------------------------------------------------------------
-------------------------------------------------------------------
create table project (
  project_id serial primary key,
  project_name varchar(2048),
  funder_project_code varchar(256),
  is_awarded boolean default false,
  inst_id varchar(256) references institution(inst_id)
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
  expected_storage numeric not null
      check (expected_storage >= 0) default 0,
  project_awarded date,
  project_start date,
  project_end date,
  sc_id integer references storage_costs(sc_id)
    on delete restrict,
  check (has_dmp_been_reviewed in ('yes', 'no', 'unknown'))
);
comment on table project is 'Describes an institutions projects';
comment on column project.funder_project_code is
  'A code assigned to the project by the funding body, it may be null
  if the funding application is in process.';
comment on column project.is_awarded is
  'Is ''true'' if funding has been succesfully applied
  for, ''false'' otherwise';
comment on column project.has_dmp is
  'Is ''true'' if a DMP exists, ''false'' otherwise.';
comment on column project.has_dmp_been_reviewed is
  'Is ''true'' if a DMP exists and has been reviewed, ''false'' otherwise.';
comment on column project.expected_storage is
  'The amount of storage in GB this project is expecting to need.';



-------------------------------------------------------------------
-------------------------------------------------------------------
create or replace view project_status as
  select
    project_id,
    (
      case when
        project.project_end > now()
      then
        'active'
      else
        'inactive'
      end
    ) status
  from
    project
;



-------------------------------------------------------------------
-------------------------------------------------------------------
create table users (
  username varchar(64),
  name varchar(256),
  inst_id varchar(256) references institution(inst_id)
    on delete cascade on update cascade not null,
  email varchar(1024),
  phone varchar(128),
  passwd varchar(128),
  unique(username, inst_id)
);



-------------------------------------------------------------------
-------------------------------------------------------------------
create table dataset (
  dataset_id serial primary key,
  project_id integer references project(project_id)
    on delete cascade on update cascade,
  dataset_pid varchar(256),
  dataset_link varchar(8192),
  dataset_size numeric default 0,
  dataset_name varchar(256),
  dataset_format varchar(256),
  dataset_notes varchar(2048),
  repository_pid varchar(2048),
  inst_archive_status varchar(256),
  archive_pid varchar(2048),
  storage_location varchar(50),
  lead_faculty_id integer references faculty(faculty_id)
    on delete cascade on update cascade,
  lead_department_id integer references department(department_id)
    on delete cascade on update cascade,
  check (storage_location in ('internal', 'external')),
  check (inst_archive_status in ('archived', 'not_archived', 'unknown'))
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



-------------------------------------------------------------------
-------------------------------------------------------------------
create table dataset_accesses (
  dataset_id integer references dataset(dataset_id)
    on delete cascade on update cascade,
  access_type varchar(64),
  access_date date,
  counter integer,
  check (access_type in ('metadata', 'data_download'))
);
create index on dataset_accesses(dataset_id);
create index on dataset_accesses(access_type);
create index on dataset_accesses(access_date);



-------------------------------------------------------------------
-------------------------------------------------------------------
create table publication (
  publication_id serial primary key,
  project_id integer references project(project_id)
    on delete cascade on update cascade,
  cris_id varchar(256),
  repo_id varchar(256),
  publication_pid varchar(256),
  funder_project_code varchar(256),
  lead_inst_id varchar(256) references institution(inst_id)
    on delete cascade on update cascade,
  lead_faculty_id integer references faculty(faculty_id)
    on delete cascade on update cascade,
  lead_department_id integer references department(department_id)
    on delete cascade on update cascade,
  publication_date date,
  data_access_statement varchar(50),
  check (data_access_statement in ('exists with no dataset',
                                   'does not exist', 'exists without link',
                                   'exists with link',
                                   'exists with persistent link'))
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
comment on column publication.data_access_statement is
  'Describes the state of the publications Data Access Statement.
  Permissible values are ''exists with no dataset'', ''does not exist'',
  ''exists without link'', ''exists with link'',
  ''exists with persistent link''';



-------------------------------------------------------------------
-------------------------------------------------------------------
create table pub_ds_map (
  publication_id integer references publication(publication_id)
    on delete cascade on update cascade not null,
  dataset_id integer references dataset(dataset_id)
    on delete cascade on update cascade not null
);
comment on table pub_ds_map is 'Maps publications to datasets.';

create index on pub_ds_map(publication_id);
create index on pub_ds_map(dataset_id);


-------------------------------------------------------------------
-------------------------------------------------------------------
create table dept_pub_map (
  department_id integer references department(department_id)
    on delete cascade on update cascade not null,
  publication_id integer references publication(publication_id)
    on delete cascade on update cascade not null
);
comment on table dept_pub_map is 'Maps departments to publications.';

create index on dept_pub_map(department_id);
create index on dept_pub_map(publication_id);


-------------------------------------------------------------------
-------------------------------------------------------------------
create table dept_ds_map (
  department_id integer references department(department_id)
    on delete cascade on update cascade not null,
  dataset_id integer references dataset(dataset_id)
    on delete cascade on update cascade not null
);
comment on table dept_ds_map is 'Maps departments to datasets.';

create index on dept_ds_map(department_id);
create index on dept_ds_map(dataset_id);


-------------------------------------------------------------------
-------------------------------------------------------------------
create table funder_pub_map (
  funder_id varchar(256) references funder(funder_id)
    on delete cascade on update cascade not null,
  publication_id integer references publication(publication_id)
    on delete cascade on update cascade not null
);
comment on table funder_pub_map is 'Maps funders to publications.';

create index on funder_pub_map(funder_id);
create index on funder_pub_map(publication_id);


-------------------------------------------------------------------
-------------------------------------------------------------------
create table funder_ds_map (
  funder_id varchar(256) references funder(funder_id)
    on delete cascade on update cascade not null,
  dataset_id integer references dataset(dataset_id)
    on delete cascade on update cascade not null
);
comment on table funder_ds_map is 'Maps funders to datasets.';

create index on funder_ds_map(funder_id);
create index on funder_ds_map(dataset_id);



-------------------------------------------------------------------
-------------------------------------------------------------------
create table funder_project_map (
  funder_id varchar(256) references funder(funder_id)
    on delete cascade on update cascade not null,
  project_id integer references project(project_id)
    on delete cascade on update cascade not null
);
comment on table funder_project_map is 'Maps funders to projects.';

create index on funder_project_map(funder_id);
create index on funder_project_map(project_id);


-------------------------------------------------------------------
-------------------------------------------------------------------
create table project_ds_map (
  project_id integer references project(project_id)
    on delete cascade on update cascade not null,
  dataset_id integer references dataset(dataset_id)
    on delete cascade on update cascade not null
);
comment on table project_ds_map is 'Maps projects to datasets.';

create index on project_ds_map(project_id);
create index on project_ds_map(dataset_id);



-------------------------------------------------------------------
-------------------------------------------------------------------
create table project_pub_map (
  project_id integer references project(project_id)
    on delete cascade on update cascade not null,
  publication_id integer references publication(publication_id)
    on delete cascade on update cascade not null
);
comment on table project_pub_map is 'Maps projects to publications.';

create index on project_pub_map(project_id);
create index on project_pub_map(publication_id);


-------------------------------------------------------------------
-------------------------------------------------------------------
create table inst_ds_map (
  inst_id varchar(256) references institution(inst_id)
    on delete cascade on update cascade not null,
  dataset_id integer references dataset(dataset_id)
    on delete cascade on update cascade not null
);
comment on table inst_ds_map is 'Maps institutions and datasets.';

create index on inst_ds_map(inst_id);
create index on inst_ds_map(dataset_id);


-------------------------------------------------------------------
-------------------------------------------------------------------
create or replace view dataset_faculty_map as
  select d.dataset_id, f.faculty_id
  from dataset d
  left outer join faculty f
  on d.lead_faculty_id = f.faculty_id;


-------------------------------------------------------------------
-------------------------------------------------------------------
create or replace view project_expected_storage_costs as
  select
    p.inst_id,
    p.project_id,
    s.sc_id,
    s.inst_reference description,
    p.expected_storage gb,
    round(p.expected_storage/1024*s.cost_per_tb, 2) storage_cost
  from
    project p,
    storage_costs s
  where
    p.sc_id = s.sc_id
  order by p.inst_id, p.project_id asc;

