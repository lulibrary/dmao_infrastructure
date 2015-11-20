insert into institution values
  (
    'luve_u', 'Lune Valley Enterprise University', 'John Krug',
    'j.krug@lancaster.ac.uk', '+44 1524 593099', 'Pure', 'Eprints',
    'Fedora', 'Arkivum', 'GBP', '£', 'http://lancaster.ac.uk',
    'The bottom university in the North West of the UK.',
    gen_api_key()
  ),
  (
    'lancaster', 'Lancaster University', 'Hardy Schwamm',
    'h.schwamm@lancaster.ac.uk', '+44 1524 593099', 'Pure', 'Eprints',
    'Fedora', 'Archivematica', 'GBP', '£', 'http://lancaster.ac.uk',
    'The top university in the North West of the UK.',
    gen_api_key()
)
;

insert into faculty (inst_id, name, abbreviation) values
  ('luve_u', 'Faculty of Arts and Social Sciences', 'FASS'),
  ('luve_u', 'Faculty of Science and Technology', 'FST'),
  ('luve_u', 'Faculty of Health and Medicine', 'FHM'),
  ('luve_u', 'Management School', 'LUMS')
;

insert into department (inst_id, faculty_id, name, abbreviation) values
  ('luve_u', 1, 'History', ''),
  ('luve_u', 3, 'Occupational Therapy', 'OT'),
  ('luve_u', 2, 'Engineering', 'ENG'),
  ('luve_u', 4, 'Organisation, Work & Technology', 'OWT'),
  ('luve_u', 2, 'Mathematics and Statistics', ''),
  ('luve_u', 3, 'Medical School', 'MED'),
  ('luve_u', 2, 'Psychology', ''),
  ('luve_u', 3, 'Biomedical and Life Sciences', 'BLS'),
  ('luve_u', 2, 'Physics', ''),
  ('luve_u', 4, 'Management Science', ''),
  ('luve_u', 1, 'Politics, Philosophy and Religion', 'PPR')
;


insert into funder values
  ('ahrc', 'Arts & Humanities Research Council', true),
  ('bbsrc', 'Biotechnology and Biological Sciences Research Council', true),
  ('epsrc', 'Engineering and Physical Sciences Research Council', true),
  ('esrc', 'Economic and Social Research Council', true),
  ('mrc', 'Medical Research Council', true),
  ('nerc', 'Natural Environment Research Council', true),
  ('stfc', 'Science and Technology Facilities Council', true),
  ('h2020', 'Horizon 2020', false),
  ('npl', 'National Physical Laboratory', false),
  ('oclaro', 'Oclaro Inc', false),
  ('none', 'Not funded', false)
;


insert into funder_dmp_states(funder_id, funder_state_code,
                              funder_state_name)
values
  ('h2020', 'version1', 'DMP version 1'),
  ('h2020', 'version2', 'DMP version 2'),
  ('h2020', 'version3', 'DMP version 3'),
  ('nerc', 'outline_dmp', 'Outline DMP'),
  ('nerc', 'full_dmp', 'Full DMP'),
  ('ahrc', 'application_dmp',  'DMP required at application stage'),
  ('bbsrc', 'application_dmp',  'DMP required at application stage')
;


insert into
  dmp (dmp_source_system, dmp_ss_pid, dmp_state, dmp_status, author_orcid)
  values
    ('DMPOnline', 'gasfdasg5', 1, 'verified', 'orcid1'),
    ('Word', '', 7, 'verified', 'orcid3'),
    ('Word', '', 1, 'in progress', 'orcid1'),
    ('DMPOnline', 'oayusufy5', 2, 'completed', 'orcid2'),
    ('Word', '', 2, 'completed', 'orcid1'),
    ('DMPOnline', 'ljasf878', 2, 'completed', 'orcid1'),
    ('Word', '', 2, 'verified', 'orcid4'),
    ('Word', '', 2, 'verified', 'orcid5'),
    ('Word', '', 2, 'verified', 'orcid7')
;

insert into inst_storage_platforms
  (inst_id, inst_storage_platform_id, inst_notes)
  values
    ('luve_u', 'hcp', 'Hitachi Content Platform'),
    ('luve_u', 'box', 'Box Cloud Storage'),
    ('luve_u', 'ark', 'Arkivum'),
    ('lancaster', 'hcp', 'Hitachi Content Platform'),
    ('lancaster', 'box', 'Box Cloud Storage'),
    ('lancaster', 'arc', 'Archivematica')
;


insert into inst_storage_costs
  (inst_id, inst_storage_platform_id,
   cost_per_tb_pa, applicable_dates)
  values
    ('luve_u', 'hcp', 8.76, '[2000-01-01,)'),
    ('luve_u', 'box', 10.00, '[2000-01-01,2017-12-31)'),
    ('luve_u', 'box', 9.00, '[2018-01-01,)'),
    ('luve_u', 'ark', 100.00, '[2000-01-01,2015-07-01)'),
    ('luve_u', 'ark', 90.00, '[2015-08-01,2017-06-30)'),
    ('luve_u', 'ark', 85.00, '[2017-07-01,)')
;


insert into project
  (project_name,
   funder_project_code,
   is_awarded,
   inst_id,
   lead_faculty_id,
   lead_department_id,
   institution_project_code,
   has_dmp,
   has_dmp_been_reviewed,
   dmp_id,
   project_awarded,
   project_date_range)
  values
    ('Intractable Likelihood: New Challenges '
      'From Modern Applications (iLike)',
     'EP/K014463/1',
     true,
     'luve_u',
     2,
     5,
     'MAA7754',
     true,
     'unknown',
     1,
     '2012-12-01',
     '[2013-01-01,2017-12-31)'),
    ('FST CASE Studentship: Design and testing of a Novel Neutron Meter',
     null,
     true,
     'luve_u',
     2,
     3,
     'EGA7804',
     true,
     'yes',
     null,
     '2013-02-12',
     '[2013-04-01,2016-09-30)'),
    ('ESRC studentship Blything',
     'EP/J019585/1',
     true,
     'luve_u',
     2,
     7,
     '',
     false,
     'no',
     null,
     '2013-02-12',
     '(2011-10-01,2015-09-30)'),
    ('Orbit-based methods for Multielectron Systems in Strong Fields',
     'EP/J019585/1',
     true,
     'luve_u',
     2,
     9,
     'PYA7995',
     false,
     'no',
     null,
     '2012-10-01',
     '[2012-10-01,2016-01-31)'),
    ('GaInAsNSb quantum wells for GaAs-based Telecoms devices',
     'PYA7943',
     true,
     'luve_u',
     2,
     9,
     'PYA7943',
     false,
     'no',
     null,
     null,
     '[2010-10-01,2014-03-31)'),
    ('Quasiparticle imaging and superfluid flow experiments at '
     'ultralow temperatures',
     'EP/I028285/1',
     true,
     'luve_u',
     2,
     9,
     'PYA7955',
     false,
     'no',
      null,
     '2011-05-24',
     '[2011-10-01,2015-09-30)'),
    ('Superfluid 3He at UltraLow Temperatures',
     'EP/L000016/1',
     true,
     'luve_u',
     2,
     9,
     'PYA7018',
     false,
     'no',
     null,
     '2013-05-24',
     '[2013-07-01,2017-06-30)'),
    ('Islam on campus',
     '',
     false,
     'luve_u',
     1,
     11,
     '51263',
     true,
     'yes',
     5,
     null,
     '[2015-06-01,2018-05-31)'),
    ('The effects of age on temporal coding in the auditory system',
     'BB/M007243/1',
     true,
     'luve_u',
     2,
     7,
     'PSA7830',
     true,
     'yes',
     7,
     '2015-01-08',
     '[2015-05-01,2018-04-30)'),
    ('Elucidating the neural mechanisms by which evolutionarily '
     'conserved intracellular signalling pathway',
    null,
    false,
    'luve_u',
    3,
    6,
    '52501',
    true,
    'yes',
    8,
    null,
    '[2016-01-01,2020-12-31)'),
    ('Elucidating the functional brain networks underlying cognitive '
     'flexibility and attention through tas',
    null,
    false,
    'luve_u',
    3,
    6,
    '52566',
    true,
    'yes',
    9,
    null,
    '[2015-12-07,2018-12-06)')
  ;

insert into project_storage_requirement
  (
    inst_id,
    project_id,
    inst_storage_platform_id,
    expected_storage,
    keep_until
  ) values
    ('luve_u', 1, 'ark', 10, null),
    ('luve_u', 1, 'box', 2500, null),
    ('luve_u', 1, 'hcp', 5500, null),
    ('luve_u', 2, 'ark', 2, null),
    ('luve_u', 2, 'box', 2, null),
    ('luve_u', 2, 'hcp', 2, null),
    ('luve_u', 3, 'ark', 2, null),
    ('luve_u', 3, 'box', 2, null),
    ('luve_u', 3, 'hcp', 2, null),
    ('luve_u', 4, 'ark', 2, null),
    ('luve_u', 4, 'box', 2, null),
    ('luve_u', 4, 'hcp', 2, null),
    ('luve_u', 5, 'hcp', 200, null),
    ('luve_u', 5, 'box', 2000, null),
    ('luve_u', 5, 'ark', 5, null),
    ('luve_u', 6, 'ark', 2, null),
    ('luve_u', 6, 'box', 2, null),
    ('luve_u', 6, 'hcp', 2, null),
    ('luve_u', 7, 'ark', 2, null),
    ('luve_u', 7, 'box', 2, null),
    ('luve_u', 7, 'hcp', 2, null),
    ('luve_u', 9, 'ark', 50, null),
    ('luve_u', 9, 'hcp', 50, null),
    ('luve_u', 9, 'box', 50, null),
    ('luve_u', 10, 'ark', 10000, null),
    ('luve_u', 10, 'box', 20000, '2021-12-31'),
    ('luve_u', 10, 'hcp', 500, '2021-12-31'),
    ('luve_u', 11, 'ark', 500, null),
    ('luve_u', 11, 'box', 500, null),
    ('luve_u', 11, 'hcp', 500, null)
  ;

insert into users values
  (
    'dladmin', 'John Krug', 'luve_u', 'j.krug@lancaster.ac.uk',
    '+441523593099', encrypt_password('dladmin')
  ),
  (
    'krug', 'John Krug', 'luve_u', 'j.krug@lancaster.ac.uk',
    '+441523593099', encrypt_password('test_password')
  ),
  (
    'krug', 'John Krug', 'lancaster', 'j.krug@lancaster.ac.uk',
    '+441523593099', '66f932609d0197b43e4e556ecbd346ace42f50ae492158592445e7b9'
  ),
  (
    'aac', 'Adrian Albin-Clark', 'luve_u', 'a.albin-clark@lancaster.ac.uk',
    '+441523593099', encrypt_password('letmein')
  )
;


insert into dataset (inst_id, project_id, dataset_pid, dataset_link,
                     dataset_size,
                     dataset_name, dataset_format, dataset_notes,
                     inst_archive_status, storage_location,
                     lead_faculty_id, lead_department_id)
values
  ('luve_u', 1, '10.17635/lancaster/researchdata/2',
   'https://dx.doi.org/10.17635/lancaster/researchdata/2', 0.00051,
   'Single Locus Variant: Data and Code for Estimating '
   'Recombination Rates', 'tgz',
   'For full details of the description of the dataset, '
   'please follow the dataset link.',
   'archived', 'internal', 2, 5),
  ('luve_u', 2, '10.17635/lancaster/researchdata/7',
   'https://dx.doi.org/10.17635/lancaster/researchdata/7', 0.693,
   'Neutron assay in mixed radiation fields with a 6Li-loaded '
   'plastic scintillator', 'zip',
   'Experimental data obtained at the National Physical Laboratory, '
   'Teddington, London. This work is collected under the work outlined '
   'in the title.', 'unknown', 'internal', 2, 3),
  ('luve_u', null,'10.17635/lancaster/researchdata/1',
   'https://dx.doi.org/10.17635/lancaster/researchdata/1',0.00247,
   'AEGISS1. Syndromic surveillance of gastro-intestinal illness','txt',
   'See file AEGISS_explain.txt for information on this data-set',
   'not_archived','internal',3,6),
  ('luve_u', 3,'10.17635/lancaster/researchdata/3',
   'https://dx.doi.org/10.17635/lancaster/researchdata/3',0.00448,
   'Temporal relations in children''s sentence comprehension',
   'csv','Column 1= subject (participant number).','not_archived',
   'internal',2,7),
  ('luve_u', null,'10.17635/lancaster/researchdata/4',
   'https://dx.doi.org/10.17635/lancaster/researchdata/4',0.00031,
   'Counting Neutrons from the Spontaneous Fission of 238-U using '
   'Scintillation','zip',
   'Data used in ''Counting Neutrons from the Spontaneous Fission of '
   '238-U using Scintillation Detectors and Mixed Field Analysers'', '
   'presented at Animma 2015.','unknown','internal',2,9),
  ('luve_u', null,'10.17635/lancaster/researchdata/5',
   'https://dx.doi.org/10.17635/lancaster/researchdata/5',0.005,
   'Corrosion Behaviour of AGR SIMFUELs [Dataset]','xlsx',
   'Data for extended in-situ Raman of SIMFUEL''s, data for cyclic '
   'voltammetry in electrolyte solution for undoped UO2, 25 GWd/tU & '
   '43 GWd/tU, data for Raman showing effects of burn-up on lattice '
   'damage peak intensities, data for open circuit potential taken '
   'separately for UO2 and 43 burn-up, and also coupled.',
   'not_archived','internal',2,9),
  ('luve_u', null,'10.17635/lancaster/researchdata/6',
   'https://dx.doi.org/10.17635/lancaster/researchdata/6',0.004,
   'Ebolavirus evolution 2013-2015','zip',
   'Data used for analysis of selection and evolutionary rate in '
   'Zaire Ebolavirus variant Makona','not_archived','internal',3,9),
  ('luve_u', 4,'10.17635/lancaster/researchdata/8',
   'https://dx.doi.org/10.17635/lancaster/researchdata/8',0.003167,
   'Numerical data on coulomb-corrected strong field approximation for '
   'hydrogen','zip',
   'Numerical data on coulomb-corrected strong field approximation '
   'for hydrogen','not_archived','internal',2,9),
  ('luve_u', 5,'10.17635/lancaster/researchdata/9',
   'https://dx.doi.org/10.17635/lancaster/researchdata/9',0.000065,
   'Data set for AIP advances 2015 on GaAs quantum dots',
   'xlsx',
   'The data set corresponds to the figures (excluding schematics and '
   'images) in the associated publication. Data for each of the figures '
   'are clearly labelled, and fulfil EPSRC requirements. Full details of '
   'how the data was generated are given in the associated publication',
   'unknown','internal',2,9),
  ('luve_u', null,'10.17635/lancaster/researchdata/10',
   'https://dx.doi.org/10.17635/lancaster/researchdata/10',0.000786,
   'M3 segmented monthly data','xlsx',
   'Data used for analysis of selection and evolutionary rate in Zaire '
   'Ebolavirus variant Makona','not_archived','internal',3,8),
  ('luve_u', null,'10.17635/lancaster/researchdata/11',
   'https://dx.doi.org/10.17635/lancaster/researchdata/11',0.03,
   'Tortoise herpesvirus evolution','zip',
   'Supplementary and raw data information for paper on TeHV3 evolution',
   'unknown','internal',3,8),
  ('luve_u', 6,'10.17635/lancaster/r/researchdata/12',
   'https://dx.doi.org/10.17635/lancaster/researchdata/12',0.002276,
   'Dataset for Visualizing Pure Quantum Turbulence in Superfluid 3He: '
   'Andreev Reflection and its Spectral Properties','xlsx',
   'The data set corresponds to the figures (excluding schematics and '
   'images) in the associated publication. Data for each of the figures '
   'are clearly labelled, and fulfil EPSRC requirements. Full details of '
   'how the data was generated are given in the associated publication.',
   'not_archived','internal',2,9),
  ('luve_u', null,'10.17635/lancaster/researchdata/13',
   'https://dx.doi.org/10.17635/lancaster/researchdata/13',0.044,
   'Blood flow data','zip','Blood flow data used in ''Dynamical markers '
   'based on blood perfusion fluctuations for selecting skin melanocytic '
   'lesions for biopsy''. Sci. Rep. 2015. In Press','not_archived',
   'internal',3,8)
;


create or replace function
  random_ir(a double precision, b double precision)
  returns integer as $$
begin
  return trunc(random()*trunc(b)+trunc(a));
end
$$ language plpgsql;

create or replace function
  date_to_int(d timestamp, base integer)
  returns integer as $$
begin
  return floor(extract('epoch' from d) / (60*60*24)) - base;
end
$$ language plpgsql;

create or replace function
  random_counter(dd timestamp, a integer, b integer, c integer, d integer)
  returns integer as $$
begin
  return trunc(
      a * date_to_int(dd, 16340)^2 *
      random_ir(
          b * date_to_int(dd, 16340)/c,
          b * date_to_int(dd, 16340)/d
      )
      / 100000
  );
end
$$ language plpgsql;

create or replace function populate_dataset_accesses() returns void as $$
  declare
    tp varchar(50);
    a integer;
    b integer;
    c integer;
    d integer;
begin
  for tp in
    select m from (values ('metadata'), ('data_download')) s(m)
  loop
    case tp
      when 'metadata' then
        a = 1;
        b = 80;
        c = 8;
        d = 3;
      else
        a = 5;
        b = 1;
        c = 20;
        d = 1;
    end case;
    for ds in 1..13 loop
      insert into
        dataset_accesses
          select ds, tp , date_trunc('day', dd) :: date,
            random_counter(dd, a, b, c, d)
          from
            generate_series (
              '2014-11-01':: timestamp , '2015-07-14':: timestamp ,
              '1 day'::interval
            ) dd;
    end loop;
  end loop;
end;
$$ language plpgsql;
select * from populate_dataset_accesses();


insert into publication (inst_id, project_id, cris_id, repo_id, publication_pid,
                         funder_project_code, lead_faculty_id,
                         lead_department_id, publication_date,
                         data_access_statement, rcuk_funder_compliant)
values
  ('luve_u', 1, '68975423', '71672', '10.1214/14-AOAS795',
    'EP/K014463/1', 2, 5,
    '2015-03-01', true, 'y'),
  ('luve_u', null, '289125', '2438', '10.1002/env.712', null, 3, 6,
    '2008-05-01', false, 'n'),
  ('luve_u', 3, '81303601', '73749', null, null, 2, 7,
    '2015-01-01', true, 'y'),
  ('luve_u', null, '56480293', '69441', '10.1099/vir.0.067199-0', null,
    3, 8,
    '2014-08-01', false, 'n'),
  ('luve_u', 5, '72017672', '72289', '10.1136/ebmed-2014-110127', null,
    3, 8,
    '2015-02-01', true, 'partial'),
  ('luve_u', 5, '85850308', '74419', '10.1063/1.4922950', 'PYA7943',
    2, 8,
    '2015-06-10', false, 'n'),
  ('luve_u', null, '41842996', '67274', '10.1016/j.jbusres.2015.03.028', null,
    4, 10,
    '2015-08-01', false, 'n')
;


insert into map_pub_ds values
  (2, 3),
  (1, 2),
  (3, 4),
  (4, 7),
  (5, 7),
  (6, 9),
  (7, 10)
;



insert into map_funder_pub values
  ('epsrc', 1),
  ('esrc', 3),
  ('epsrc', 5)
;


insert into map_funder_ds
values
  ('epsrc', 1),
  ('npl', 2),
  ('none', 3),
  ('esrc', 4),
  ('none', 5),
  ('none', 6),
  ('none', 7),
  ('epsrc', 8),
  ('oclaro', 9),
  ('none', 10),
  ('none', 11),
  ('epsrc', 12),
  ('none', 13)
;


insert into map_funder_project values
  ('epsrc', 1),
  ('npl', 2),
  ('esrc', 3),
  ('epsrc', 4),
  ('oclaro', 5),
  ('epsrc', 6),
  ('epsrc', 7),
  ('ahrc', 8),
  ('bbsrc', 9),
  ('bbsrc', 10)
;


insert into map_inst_ds
values
  ('luve_u', 1),
  ('luve_u', 2),
  ('luve_u', 3),
  ('luve_u', 4),
  ('luve_u', 5),
  ('luve_u', 6),
  ('luve_u', 7),
  ('luve_u', 8),
  ('luve_u', 9),
  ('luve_u', 10),
  ('luve_u', 11),
  ('luve_u', 12),
  ('luve_u', 13)
;


