var frisby = require('frisby');
var hostname = 'centos:8070';
var hostname = 'lib-dmao.lancs.ac.uk:8070';
var base_url = 'http://' + hostname +'/dmaonline/v0.3';
var inst = 'luve_u';
var o_tests = [
    'institutions', 'faculties', 'departments',
    'dmps', 'publications', 'datasets', 'dataset_accesses'
];
var index;

// open_apis
for (index = 0; index < o_tests.length; index++) {
    var u = base_url + '/o/o_count_' + o_tests[index];
    console.log('GET ' + u);
    frisby.create('Test count ' + o_tests[index])
        .get(u)
        .expectStatus(200)
        .expectHeaderContains('content-type', 'application/json')
        .expectJSONTypes('?', {count: Number})
        .toss();
}

// o_inst_list
var u = base_url + '/o/o_inst_list';
console.log('GET ' + u);
frisby.create('Test o_inst_list')
    .get(u)
    .expectStatus(200)
    .expectHeaderContains('content-type', 'application/json')
    .expectJSONTypes('?', {inst_id: "luve_u"})
    .toss();

// o_get_api_key
var u = base_url + '/o/' + inst + '/o_get_api_key?user=krug&passwd=' +
    'some_junk';
console.log('GET ' + u);
frisby.create('Test o_get_api_key with wrong password')
    .get(u)
    .expectStatus(200)
    .expectHeaderContains('content-type', 'application/json')
    .expectBodyContains('[]')
    .toss();

var u = base_url + '/o/' + inst + '/o_get_api_key?user=krug&passwd=' +
    '3598976bfd77124e19b8af1e37c9e424a3cefdabdcb68b7e0385d01f';
console.log('GET ' + u);
frisby.create('Test o_get_api_key')
    .get(u)
    .expectStatus(200)
    .expectHeaderContains('content-type', 'application/json')
    .expectJSONTypes('?', {api_key: String})
    .afterJSON(function (json) {
        // all subsequent tests use the api_key
        var ak = json[0]['api_key'];

        // uca - use case APIs
        var standard_date_parameter_tests = [
            'date=project_awarded&sd=20150501&ed=20251231',
            'date=project_start&sd=20150501&ed=20251231',
            'date=project_end&sd=20150501&ed=20251231'
        ];
        var rcuk_date_parameter_tests = [
            'date=publication_date&sd=20150501&ed=20251231',
            'date=project_awarded&sd=20150501&ed=20251231',
            'date=project_start&sd=20150501&ed=20251231',
            'date=project_end&sd=20150501&ed=20251231'
        ];
        var standard_faculty_dept_parameter_tests = [
            'faculty=1', 'faculty=2', 'faculty=3', 'faculty=4', 'faculty=5',
            'faculty=6', 'faculty=7', 'dept=1',
            'dept=2', 'dept=3', 'dept=4', 'dept=5', 'dept=6',
            'dept=7', 'dept=8'
        ];
        var uca = [
            {
                api_call: 'datasets',
                parameter_tests:
                    standard_date_parameter_tests.concat(
                        standard_faculty_dept_parameter_tests
                    ).concat(
                        'dataset_id=1',
                        'dataset_id=1999',
                        'arch_status=archived',
                        'arch_status=not_archived',
                        'arch_status=unknown',
                        'location=internal',
                        'location=external',
                        'filter=rcuk'
                    )
            },
            {
                api_call: 'project_dmps',
                parameter_tests:
                    standard_date_parameter_tests.concat(
                        standard_faculty_dept_parameter_tests
                    ).concat(
                        'modifiable=true',
                        'project_id=1',
                        'has_dmp=true',
                        'has_dmp=false',
                        'dmp_reviewed=yes',
                        'dmp_reviewed=no',
                        'dmp_reviewed=unknown',
                        'is_awarded=true',
                        'is_awarded=false'
                    )
            },
            {
                api_call: 'dmp_status',
                parameter_tests:
                    standard_date_parameter_tests.concat(
                        standard_faculty_dept_parameter_tests
                    ).concat(
                        'project_id=1',
                        'has_dmp=true',
                        'has_dmp=false',
                        'dmp_reviewed=yes',
                        'dmp_reviewed=no',
                        'dmp_reviewed=unknown'
                        // todo: dmp_status & dmp_state tests required
                    )
            },
            {
                api_call: 'storage',
                parameter_tests:
                    standard_date_parameter_tests.concat(
                        standard_faculty_dept_parameter_tests
                    ).concat(
                        'modifiable=true',
                        'ispi_list=true',
                        'project_id=2',
                        'dataset_id=4'
                    )
            },
            {
                api_call: 'rcuk_as',
                parameter_tests:
                    standard_date_parameter_tests.concat(
                        standard_faculty_dept_parameter_tests
                    ).concat(
                        'project_id=1',
                        'funder=ahrc',
                        'funder_project_code=EP/K014463/1'
                    ).concat(
                        rcuk_date_parameter_tests
                    )
            },
            {
                api_call: 'dataset_accesses',
                parameter_tests: [
                    'sd=20150501&ed=20251231',
                    'sd=20150501&ed=20251231',
                    'sd=20150501&ed=20251231'
                ].concat(standard_faculty_dept_parameter_tests)
            }
        ];

        var u = base_url + '/c/' + inst + '/' + ak + '/faculties_departments';
        console.log('\nGET ' + u);
        frisby.create('Test faculty/department map')
            .get(u)
            .expectStatus(200)
            .expectHeaderContains('content-type', 'application/json')
            .toss();

        var api_keys = [
            {
                api_key: ak,
                expected_status: 200,
                expected_content: 'application/json'
            },
            {
                api_key: 'junk_key',
                expected_status: 403,
                expected_content: 'text/html'
            }
        ];

        for (var t = 0; t < uca.length; t++) {
            var test = uca[t].api_call;
            var p_tests = uca[t].parameter_tests;
            for (var a = 0; a < api_keys.length; a++) {
                var bu = base_url + '/c/' + inst + '/' +
                    api_keys[a].api_key + '/' + test;
                var expected_status = api_keys[a].expected_status;
                var expected_content = api_keys[a].expected_content;
                console.log('GET ' + bu);
                frisby.create('Test ' + test)
                    .get(bu)
                    .expectStatus(expected_status)
                    .expectHeaderContains('content-type', expected_content)
                    .toss();
                for (var p = 0; p < p_tests.length; p++) {
                    var parameter = p_tests[p];
                    u = bu + '?' + parameter;
                    console.log('GET ' + u);
                    frisby.create('Test ' + test +
                        ' with parameters ' + parameter)
                        .get(u)
                        .expectStatus(expected_status)
                        .expectHeaderContains('content-type', expected_content)
                        .toss();
                }
            }
        }

        var u = base_url + '/c/' + inst + '/' + ak + '/project_dmps' +
            '?project_id=1&has_dmp=true&has_dmp_been_reviewed=unknown';
        console.log('PUT ' + u);
        frisby.create('test project_dmps put')
            .put(u)
            .expectStatus(200)
            .expectHeaderContains('content-type', 'application/json')
            .toss();

        u = base_url + '/c/' + inst + '/' + ak + '/project_dmps' +
            '?project_id=1&has_dmp_been_reviewed=unknown';
        console.log('PUT ' + u);
        frisby.create('test project_dmps put')
            .put(u)
            .expectStatus(200)
            .expectHeaderContains('content-type', 'application/json')
            .toss();

        u = base_url + '/c/' + inst + '/' + ak + '/project_dmps' +
            '?project_id=1&has_dmp=true';
        console.log('PUT ' + u);
        frisby.create('test project_dmps put')
            .put(u)
            .expectStatus(200)
            .expectHeaderContains('content-type', 'application/json')
            .toss();

        u = base_url + '/c/' + inst + '/' + ak + '/storage' +
            '?project_id=1' + '&inst_storage_platform_id=hcp' +
            '&expected_storage=99'
        console.log('PUT ' + u);
        frisby.create('test storage put')
            .put(u)
            .expectStatus(200)
            .expectHeaderContains('content-type', 'application/json')
            .toss();

        u = base_url + '/c/' + inst + '/' + ak + '/storage' +
            '?project_id=1' + '&inst_storage_platform_id=hcp' +
            '&expected_storage=0';
        console.log('PUT ' + u);
        frisby.create('test storage put, 0 value')
            .put(u)
            .expectStatus(200)
            .expectHeaderContains('content-type', 'application/json')
            .toss();

        u = base_url + '/c/' + inst + '/' + ak + '/storage' +
            '?project_id=1' +
            '&expected_storage=99';
        console.log('PUT ' + u);
        frisby.create('test storage put with no storage platform specified')
            .put(u)
            .expectStatus(400)
            .expectHeaderContains('content-type', 'text/html')
            .toss();

        u = base_url + '/c/' + inst + '/' + ak + '/storage' +
            '?inst_storage_platform_id=box' +
            '&expected_storage=99';
        console.log('PUT ' + u);
        frisby.create('test storage put with no project')
            .put(u)
            .expectStatus(400)
            .expectHeaderContains('content-type', 'text/html')
            .toss();

        u = base_url + '/c/' + inst + '/' + ak + '/publications_editor' +
            '?publication_id=3&data_access_statement_notes=Hello%20World!' +
            '&data_access_statement=y&funder_compliant=n';
        console.log('PUT ' + u);
        frisby.create('test publications_editor put')
            .put(u)
            .expectStatus(200)
            .expectHeaderContains('content-type', 'application/json')
            .toss();

        u = base_url + '/c/' + inst + '/' + ak + '/publications_editor' +
            '?data_access_statement_notes=Hello%20World!' +
            '&data_access_statement=y&funder_compliant=n';
        console.log('PUT ' + u);
        frisby.create('test publications_editor put, no publication_id')
            .put(u)
            .expectStatus(400)
            .expectHeaderContains('content-type', 'text/html')
            .toss();

    })
    .toss();
