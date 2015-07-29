insert into institution values
  (
    'lancaster', 'Lancaster University', 'John Krug',
    'j.krug@lancaster.ac.uk', '+44 1524 593099', 'Pure', 'Eprints',
    'Fedora', 'Archivematica', 'GBP', '£'
  )
;

insert into faculty (inst_id, name, abbreviation) values
  ('lancaster', 'Faculty of Arts and Social Sciences', 'FASS'),
  ('lancaster', 'Faculty of Science and Technology', 'FST'),
  ('lancaster', 'Faculty of Health and Medicine', 'FHM'),
  ('lancaster', 'Management School', 'LUMS')
;

insert into department (inst_id, faculty_id, name, abbreviation) values
  ('lancaster', 1, 'History', ''),
  ('lancaster', 3, 'Occupational Therapy', 'OT'),
  ('lancaster', 2, 'Engineering', 'ENG'),
  ('lancaster', 4, 'Organisation, Work & Technology', 'OWT'),
  ('lancaster', 2, 'Mathematics and Statistics', ''),
  ('lancaster', 3, 'Medical School', 'MED'),
  ('lancaster', 2, 'Psychology', ''),
  ('lancaster', 3, 'Biomedical and Life Sciences', 'BLS'),
  ('lancaster', 2, 'Physics', ''),
  ('lancaster', 4, 'Management Science', ''),
  ('lancaster', 1, 'Politics, Philosophy and Religion', 'PPR')
;


insert into funder values
  ('ahrc', 'Arts & Humanities Research Council'),
  ('bbsrc', 'Biotechnology and Biological Sciences Research Council'),
  ('epsrc', 'Engineering and Physical Sciences Research Council'),
  ('esrc', 'Economic and Social Research Council'),
  ('mrc', 'Medical Research Council'),
  ('nerc', 'Natural Environment Research Council'),
  ('stfc', 'Science and Technology Facilities Council'),
  ('h2020', 'Horizon 2020'),
  ('npl', 'National Physical Laboratory'),
  ('oclaro', 'Oclaro Inc'),
  ('none', 'Not funded')
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
    ('DMPonline', 'gasfdasg5', 1, 'verified', 'orcid1'),
    ('Word', '', 7, 'verified', 'orcid3'),
    ('Word', '', 1, 'in progress', 'orcid1'),
    ('DMPonline', 'oayusufy5', 2, 'completed', 'orcid2'),
    ('Word', '', 2, 'completed', 'orcid1'),
    ('DMPonline', 'ljasf878', 2, 'completed', 'orcid1'),
    ('Word', '', 2, 'verified', 'orcid4'),
    ('Word', '', 2, 'verified', 'orcid5'),
    ('Word', '', 2, 'verified', 'orcid7')
;

insert into storage_costs(inst_id, inst_reference, cost_per_tb)
  values
    ('lancaster', 'Hitachi Content Platform', 8.76),
    ('lancaster', 'Box Cloud Storage', 2.89),
    ('lancaster', 'Arkivum', 80.00)
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
   expected_storage,
   project_awarded,
   project_start,
   project_end,
   sc_id)
  values
    ('Intractable Likelihood: New Challenges '
      'From Modern Applications (iLike)',
     'EP/K014463/1',
     true,
     'lancaster',
     2,
     5,
     'MAA7754',
     false,
     'no',
     null,
     2500,
     '2012-12-01', '2013-01-01', '2017-12-31', 1),
    ('FST CASE Studentship: Design and testing of a Novel Neutron Meter',
     null,
     true,
     'lancaster',
     2,
     3,
     'EGA7804',
     true,
     'yes',
     1,
     2,
     '2013-02-12', '2013-04-01', '2016-09-30', 1),
    ('ESRC studentship Blything',
     'EP/J019585/1',
     true,
     'lancaster',
     2,
     7,
     '',
     false,
     'no',
     null,
     2,
     '2013-02-12', '2011-10-01', '2015-09-30', 2),
    ('Orbit-based methods for Multielectron Systems in Strong Fields',
     'EP/J019585/1',
     true,
     'lancaster',
     2,
     9,
     'PYA7995',
     false,
     'no',
     null,
     2,
     '2012-10-01', '2012-10-01', '2016-01-31', 1),
    ('GaInAsNSb quantum wells for GaAs-based Telecoms devices',
     'PYA7943',
     true,
     'lancaster',
     2,
     9,
     'PYA7943',
     false,
     'no',
     null,
     2,
     null, '2010-10-01', '2014-03-31', 2),
    ('Quasiparticle imaging and superfluid flow experiments at '
     'ultralow temperatures',
     'EP/I028285/1',
     true,
     'lancaster',
     2,
     9,
     'PYA7955',
     false,
     'no',
      null,
      2,
     '2011-05-24', '2011-10-01', '2015-09-30', 2),
    ('Superfluid 3He at UltraLow Temperatures',
     'EP/L000016/1',
     true,
     'lancaster',
     2,
     9,
     'PYA7018',
     false,
     'no',
     null, 2,
     '2013-05-24', '2013-07-01', '2017-06-30', 2),
    ('Islam on campus',
     '',
     false,
     'lancaster',
     1,
     11,
     '51263',
     true,
     'yes',
     5,
     0,
     null, '2015-06-01', '2018-05-31', 2),
    ('The effects of age on temporal coding in the auditory system',
     'BB/M007243/1',
     true,
     'lancaster',
     2,
     7,
     'PSA7830',
     true,
     'yes',
     7,
     50,
     '2015-01-08', '2015-05-01', '2018-04-30', 1),
    ('Elucidating the neural mechanisms by which evolutionarily '
     'conserved intracellular signalling pathway',
    null,
    false,
    'lancaster',
    3,
    6,
    '52501',
    true,
    'yes',
    8,
    10000,
    null, '2016-01-01', '2020-12-31', 3),
    ('Elucidating the functional brain networks underlying cognitive '
     'flexibility and attention through tas',
    null,
    false,
    'lancaster',
    3,
    6,
    '52566',
    true,
    'yes',
    9,
    500,
    null, '2015-12-07', '2018-12-06', 3)
  ;


insert into users values
  (
    'krug', 'John Krug', 'lancaster', 'j.krug@lancaster.ac.uk',
    '+441523593099', sha512('test_password')
  )
;


insert into dataset (project_id, dataset_pid, dataset_link, dataset_size,
                     dataset_name, dataset_format, dataset_notes,
                     inst_archive_status, storage_location,
                     lead_faculty_id, lead_department_id)
values
  (1, '10.17635/lancaster/researchdata/2',
   'https://dx.doi.org/10.17635/lancaster/researchdata/2', 0.00051,
   'Single Locus Variant: Data and Code for Estimating '
   'Recombination Rates', 'tgz',
   'For full details of the description of the dataset, '
   'please follow the dataset link.',
   'archived', 'internal', 2, 5),
  (2, '10.17635/lancaster/researchdata/7',
   'https://dx.doi.org/10.17635/lancaster/researchdata/7', 0.693,
   'Neutron assay in mixed radiation fields with a 6Li-loaded '
   'plastic scintillator', 'zip',
   'Experimental data obtained at the National Physical Laboratory, '
   'Teddington, London. This work is collected under the work outlined '
   'in the title.', 'unknown', 'internal', 2, 3),
  (null,'10.17635/lancaster/researchdata/1',
   'https://dx.doi.org/10.17635/lancaster/researchdata/1',0.00247,
   'AEGISS1. Syndromic surveillance of gastro-intestinal illness','txt',
   'See file AEGISS_explain.txt for information on this data-set',
   'not_archived','internal',3,6),
  (3,'10.17635/lancaster/researchdata/3',
   'https://dx.doi.org/10.17635/lancaster/researchdata/3',0.00448,
   'Temporal relations in children''s sentence comprehension',
   'csv','Column 1= subject (participant number).','not_archived',
   'internal',2,7),
  (null,'10.17635/lancaster/researchdata/4',
   'https://dx.doi.org/10.17635/lancaster/researchdata/4',0.00031,
   'Counting Neutrons from the Spontaneous Fission of 238-U using '
   'Scintillation','zip',
   'Data used in ''Counting Neutrons from the Spontaneous Fission of '
   '238-U using Scintillation Detectors and Mixed Field Analysers'', '
   'presented at Animma 2015.','unknown','internal',2,9),
  (null,'10.17635/lancaster/researchdata/5',
   'https://dx.doi.org/10.17635/lancaster/researchdata/5',0.005,
   'Corrosion Behaviour of AGR SIMFUELs [Dataset]','xlsx',
   'Data for extended in-situ Raman of SIMFUEL''s, data for cyclic '
   'voltammetry in electrolyte solution for undoped UO2, 25 GWd/tU & '
   '43 GWd/tU, data for Raman showing effects of burn-up on lattice '
   'damage peak intensities, data for open circuit potential taken '
   'separately for UO2 and 43 burn-up, and also coupled.',
   'not_archived','internal',2,9),
  (null,'10.17635/lancaster/researchdata/6',
   'https://dx.doi.org/10.17635/lancaster/researchdata/6',0.004,
   'Ebolavirus evolution 2013-2015','zip',
   'Data used for analysis of selection and evolutionary rate in '
   'Zaire Ebolavirus variant Makona','not_archived','internal',3,9),
  (4,'10.17635/lancaster/researchdata/8',
   'https://dx.doi.org/10.17635/lancaster/researchdata/8',0.003167,
   'Numerical data on coulomb-corrected strong field approximation for '
   'hydrogen','zip',
   'Numerical data on coulomb-corrected strong field approximation '
   'for hydrogen','not_archived','internal',2,9),
  (5,'10.17635/lancaster/researchdata/9',
   'https://dx.doi.org/10.17635/lancaster/researchdata/9',0.000065,
   'Data set for AIP advances 2015 on GaAs quantum dots',
   'xlsx',
   'The data set corresponds to the figures (excluding schematics and '
   'images) in the associated publication. Data for each of the figures '
   'are clearly labelled, and fulfil EPSRC requirements. Full details of '
   'how the data was generated are given in the associated publication',
   'unknown','internal',2,9),
  (null,'10.17635/lancaster/researchdata/10',
   'https://dx.doi.org/10.17635/lancaster/researchdata/10',0.000786,
   'M3 segmented monthly data','xlsx',
   'Data used for analysis of selection and evolutionary rate in Zaire '
   'Ebolavirus variant Makona','not_archived','internal',3,8),
  (null,'10.17635/lancaster/researchdata/11',
   'https://dx.doi.org/10.17635/lancaster/researchdata/11',0.03,
   'Tortoise herpesvirus evolution','zip',
   'Supplementary and raw data information for paper on TeHV3 evolution',
   'unknown','internal',3,8),
  (6,'10.17635/lancaster/r/researchdata/12',
   'https://dx.doi.org/10.17635/lancaster/researchdata/12',0.002276,
   'Dataset for Visualizing Pure Quantum Turbulence in Superfluid 3He: '
   'Andreev Reflection and its Spectral Properties','xlsx',
   'The data set corresponds to the figures (excluding schematics and '
   'images) in the associated publication. Data for each of the figures '
   'are clearly labelled, and fulfil EPSRC requirements. Full details of '
   'how the data was generated are given in the associated publication.',
   'not_archived','internal',2,9),
  (null,'10.17635/lancaster/researchdata/13',
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


insert into publication (project_id, cris_id, repo_id, publication_pid,
                         funder_project_code, lead_inst_id, lead_faculty_id,
                         lead_department_id, publication_date,
                         data_access_statement)
values
  (1, '68975423', '71672', '10.1214/14-AOAS795',
    'EP/K014463/1', 'lancaster', 2, 5,
    '2015-03-01', 'does not exist'),
  (null, '289125', '2438', '10.1002/env.712', null, 'lancaster', 3, 6,
    '2008-05-01', 'does not exist'),
  (3, '81303601', '73749', null, null, 'lancaster', 2, 7,
    '2015-01-01', 'exists with persistent link'),
  (null, '56480293', '69441', '10.1099/vir.0.067199-0', null,
    'lancaster', 3, 8,
    '2014-08-01', 'does not exist'),
  (5, '72017672', '72289', '10.1136/ebmed-2014-110127', null,
    'lancaster', 3, 8,
    '2015-02-01', 'exists with link'),
  (5, '85850308', '74419', '10.1063/1.4922950', 'PYA7943',
    'lancaster', 2, 8,
    '2015-06-10', 'does not exist'),
  (null, '41842996', '67274', '10.1016/j.jbusres.2015.03.028', null,
    'lancaster', 4, 10,
    '2015-08-01', 'does not exist')
;


insert into pub_ds_map values
  (2, 3),
  (1, 2),
  (3, 4),
  (4, 7),
  (5, 7),
  (6, 9),
  (7, 10)
;



insert into funder_pub_map values
  ('epsrc', 1),
  ('esrc', 3),
  ('epsrc', 5)
;


insert into funder_ds_map
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


insert into funder_project_map values
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


insert into inst_ds_map
values
  ('lancaster', 1),
  ('lancaster', 2),
  ('lancaster', 3),
  ('lancaster', 4),
  ('lancaster', 5),
  ('lancaster', 6),
  ('lancaster', 7),
  ('lancaster', 8),
  ('lancaster', 9),
  ('lancaster', 10),
  ('lancaster', 11),
  ('lancaster', 12),
  ('lancaster', 13)
;


