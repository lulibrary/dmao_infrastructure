-- Use cases from Hardy:
-- 1. How many datasets are produced at my institution with
-- funding from RCUK?
--
-- Why?
--
--   * To provide support at various stages of the lifecycle
--   * To monitor compliance
--   * To provide reports
--
--
-- 2.a) I'd like to know how many DMPs have been produced at my
--      institution/faculty/department?
-- 2.b) How many funded projects do not have a DMP?
--
--   * To provide support
--   * To monitor compliance
--
--
-- 3. As an RDM manager I'd like to know about all projects,
-- their respective funders and the status of the DMPs in order to
--
--    * provide support
--    * see how advanced the DMP is (version? important for H2020/NERC)

-- Use case 3 (revised): As an RDM manager I'd like to know about the status of
-- DMPs, especially by funders that ask for different versions of DMP during
-- the lifetime of a research project
--
--
-- 4. I'd like to know how much data storage is actually
-- allocated/ expected allocation / allocation vs real use
--
-- 5. I'd like to know how many RCUK funded publications contain a
-- data access statements and persistent identifiers?
-- Use case 5 (revised): As an RDM Manager I'd like to know how many
-- RCUK funded research publications include a correct data access
-- statements and persistent identifiers


-- 1
select * from dataset
where dataset_id in (
  select dataset_id from funder_ds_map
  where funder_id in ('list of funder ids of relevance')
);

-- 2.a
select count(*)
from project
where inst_id = '<inst_id>'
and has_dmp is true;

-- 2.b
select count(*) from project
where has_dmp is false and is_awarded is true;

-- 3
select * from funder_project_map, project, dmp, funder
where funder_project_map.funder_id = funder.funder_id
and funder_project_map.project_id = project.project_id
and project.dmp_id = dmp.dmp_id;

-- 4
select
  project.project_id,
  expected_storage,
  dataset_id,
  dataset_pid,
  dataset_size
from project, dataset
where project.project_id = dataset.project_id;

-- 5
select
  funder_pub_map.funder_id,
  publication.data_access_statement,
  publication.publication_pid
from
  funder_pub_map, publication
where
  funder_pub_map.funder_id in ('list of rcuk funder ids')
and
  funder_pub_map.publication_id = publication.publication_id;