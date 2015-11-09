var frisby = require('frisby');
var base_url = 'http://localhost:8070/dmaonline/v0.3';
var o_tests = [
    'institutions', 'faculties', 'departments',
    'dmps', 'publications', 'datasets', 'dataset_accesses'
];
var index;

for (index = 0; index < o_tests.length; index++)
    frisby.create('Test count ' + o_tests[index])
        .get(base_url + '/o/o_count_' + o_tests[index])
        .expectStatus(200)
        .expectHeaderContains('content-type', 'application/json')
        .expectJSONTypes('?', {count: Number})
        .toss();

frisby.create('Test o_inst_list')
    .get(base_url + '/o/o_inst_list')
    .expectStatus(200)
    .expectHeaderContains('content-type', 'application/json')
    .expectJSONTypes('?', {inst_id: "d_lancaster"})
    .toss();

frisby.create('Test o_get_api_key with wrong password')
    .get(base_url + '/o/d_lancaster/o_get_api_key?user=krug&passwd=' +
    'some_junk')
    .expectStatus(200)
    .expectHeaderContains('content-type', 'application/json')
    .expectBodyContains('{}')
    .toss();

frisby.create('Test o_get_api_key')
    .get(base_url + '/o/d_lancaster/o_get_api_key?user=krug&passwd=' +
    '3598976bfd77124e19b8af1e37c9e424a3cefdabdcb68b7e0385d01f')
    .expectStatus(200)
    .expectHeaderContains('content-type', 'application/json')
    .expectJSONTypes('?', {api_key: String})
    .afterJSON(function (json) {
        // all subsequent tests use the api_key
        var ak = json[0]['api_key'];

        frisby.create('Test project_dmps with bad api_key')
            .get(base_url + '/c/d_lancaster/' + 'junk' +
            '/project_dmps?project_id=1')
            .expectStatus(403)
            .expectHeaderContains('content-type', 'text/html')
            .toss();

        frisby.create('Test project_dmps modifiables')
            .get(base_url + '/c/d_lancaster/' + ak +
            '/project_dmps?modifiable=true')
            .expectStatus(200)
            .expectHeaderContains('content-type', 'application/json')
            .toss();

        frisby.create('Test project_dmps')
            .get(base_url + '/c/d_lancaster/' + ak + '/project_dmps')
            .expectStatus(200)
            .expectHeaderContains('content-type', 'application/json')
            .expectJSONTypes('?', {has_dmp_been_reviewed: String})
            .expectJSONTypes('?', {project_acronym: String})
            .expectJSONTypes('?', {project_id: Number})
            .toss();

        frisby.create('Test project_dmps with project_id filter')
            .get(base_url + '/c/d_lancaster/' + ak +
            '/project_dmps?project_id=1')
            .expectStatus(200)
            .expectHeaderContains('content-type', 'application/json')
            .expectJSONTypes('?', {has_dmp_been_reviewed: String})
            .expectJSONTypes('?', {project_acronym: String})
            .expectJSONTypes('?', {project_id: Number})
            .toss();

        frisby.create('Test project_dmps with count filter')
            .get(base_url + '/c/d_lancaster/' + ak +
            '/project_dmps?count=true&project_id=1')
            .expectStatus(200)
            .expectHeaderContains('content-type', 'application/json')
            .expectJSON([{"num_project_dmps": 1}])
            .toss();

        var dmp_reviewed = ["yes", "no", "unknown"];
        for (index = 0; index < dmp_reviewed.length; index++)
            frisby.create('Test project_dmps with filter dmp_reviewed = '
                + dmp_reviewed[index])
                .get(base_url + '/c/d_lancaster/' + ak +
                '/project_dmps?dmp_reviewed='
                + dmp_reviewed[index])
                .expectStatus(200)
                .expectHeaderContains('content-type', 'application/json')
                .expectJSONTypes('?', {project_id: Number})
                .toss();

        var has_dmp = ["true", "false"];
        for (index = 0; index < has_dmp.length; index++)
            frisby.create('Test project_dmps with filter has_dmp = '
                + has_dmp[index])
                .get(base_url + '/c/d_lancaster/' + ak +
                '/project_dmps?has_dmp=' + has_dmp[index])
                .expectStatus(200)
                .expectHeaderContains('content-type', 'application/json')
                .toss();

        var is_awarded = ["true", "false"];
        for (index = 0; index < is_awarded.length; index++)
            frisby.create('Test project_dmps with filter is_awarded = '
                + has_dmp[index])
                .get(base_url + '/c/d_lancaster/' + ak +
                '/project_dmps?is_awarded=' + is_awarded[index])
                .expectStatus(200)
                .expectHeaderContains('content-type', 'application/json')
                .toss();

        var project_dmps_date_types = [
            "project_awarded", "project_start", "project_end"
        ];
        for (index = 0; index < project_dmps_date_types.length; index++)
            frisby.create('Test project_dmps with filter date range = '
                + project_dmps_date_types[index])
                .get(base_url + '/c/d_lancaster/' + ak +
                '/project_dmps?date=' + project_dmps_date_types[index] +
                '&sd=20000101&ed=20171231')
                .expectStatus(200)
                .expectHeaderContains('content-type', 'application/json')
                .toss();

        frisby.create('Test project_dmps with filter by faculty')
            .get(base_url + '/c/d_lancaster/' + ak + '/project_dmps?faculty=2')
            .expectStatus(200)
            .expectHeaderContains('content-type', 'application/json')
            .toss();

        frisby.create('Test project_dmps with filter by department')
            .get(base_url + '/c/d_lancaster/' + ak + '/project_dmps?dept=2')
            .expectStatus(200)
            .expectHeaderContains('content-type', 'application/json')
            .toss();

        frisby.create('Test dmp_status')
            .get(base_url + '/c/d_lancaster/' + ak + '/dmp_status')
            .expectStatus(200)
            .expectHeaderContains('content-type', 'application/json')
            .toss();

        frisby.create('Test dmp_status count')
            .get(base_url + '/c/d_lancaster/' + ak + '/dmp_status?count=true')
            .expectStatus(200)
            .expectHeaderContains('content-type', 'application/json')
            .toss();

        var dmp_status_date_types = [
            "project_awarded", "project_start", "project_end"
        ];
        for (index = 0; index < dmp_status_date_types.length; index++)
            frisby.create('Test dmp_status with filter date range = '
                + dmp_status_date_types[index])
                .get(base_url + '/c/d_lancaster/' + ak +
                '/dmp_status?date=' + dmp_status_date_types[index] +
                '&sd=20000101&ed=20171231')
                .expectStatus(200)
                .expectHeaderContains('content-type', 'application/json')
                .toss();

        frisby.create('Test dmp_status with project_id filter')
            .get(base_url + '/c/d_lancaster/' + ak + '/dmp_status?project_id=1')
            .expectStatus(200)
            .expectHeaderContains('content-type', 'application/json')
            .toss();

        has_dmp = ["true", "false"];
        for (index = 0; index < has_dmp.length; index++)
            frisby.create('Test dmp_status with filter has_dmp = '
                + has_dmp[index])
                .get(base_url + '/c/d_lancaster/' + ak +
                '/dmp_status?has_dmp=' + has_dmp[index])
                .expectStatus(200)
                .expectHeaderContains('content-type', 'application/json')
                .toss();

        dmp_reviewed = ["yes", "no", "unknown"];
        for (index = 0; index < dmp_reviewed.length; index++)
            frisby.create('Test dmp_status with filter dmp_reviewed = '
                + dmp_reviewed[index])
                .get(base_url + '/c/d_lancaster/' + ak +
                '/dmp_status?dmp_reviewed='
                + dmp_reviewed[index])
                .expectStatus(200)
                .expectHeaderContains('content-type', 'application/json')
                .expectJSONTypes('?', {project_id: Number})
                .toss();

        frisby.create('Test datasets')
            .get(base_url + '/c/d_lancaster/' + ak + '/datasets')
            .expectStatus(200)
            .expectHeaderContains('content-type', 'application/json')
            .toss();

        frisby.create('Test storage')
            .get(base_url + '/c/d_lancaster/' + ak + '/storage')
            .expectStatus(200)
            .expectHeaderContains('content-type', 'application/json')
            .toss();

        frisby.create('Test rcuk_as')
            .get(base_url + '/c/d_lancaster/' + ak + '/rcuk_as')
            .expectStatus(200)
            .expectHeaderContains('content-type', 'application/json')
            .toss();

        frisby.create('Test rcuk_as count')
            .get(base_url + '/c/d_lancaster/' + ak + '/rcuk_as?count=true')
            .expectStatus(200)
            .expectHeaderContains('content-type', 'application/json')
            .toss();

        var rcuk_as_date_types = [
            "pub.publication_date",
            "proj.project_awarded",
            "proj.project_start",
            "proj.project_end"
        ];
        for (index = 0; index < rcuk_as_date_types.length; index++)
            frisby.create('Test rcuk_as with filter date range = '
                + rcuk_as_date_types[index])
                .get(base_url + '/c/d_lancaster/' + ak +
                '/rcuk_as?date=' + rcuk_as_date_types[index] +
                '&sd=20000101&ed=20171231')
                .expectStatus(200)
                .expectHeaderContains('content-type', 'application/json')
                .toss();

        frisby.create('Test dataset_accesses')
            .get(base_url + '/c/d_lancaster/' + ak + '/dataset_accesses')
            .expectStatus(200)
            .expectHeaderContains('content-type', 'application/json')
            .toss();

        frisby.create('Test dataset_accesses summary')
            .get(base_url + '/c/d_lancaster/' + ak +
                '/dataset_accesses?summary=true')
            .expectStatus(200)
            .expectHeaderContains('content-type', 'application/json')
            .toss();

        frisby.create('Test dataset_accesses summary_by_date')
            .get(base_url + '/c/d_lancaster/' + ak +
                '/dataset_accesses?summary_by_date=true')
            .expectStatus(200)
            .expectHeaderContains('content-type', 'application/json')
            .toss();

        frisby.create('Test dataset_accesses with filter date range')
            .get(base_url + '/c/d_lancaster/' + ak +
            '/dataset_accesses?sd=20000101&ed=20171231')
            .expectStatus(200)
            .expectHeaderContains('content-type', 'application/json')
            .toss();

        frisby.create('Test dataset_accesses with filter by faculty')
            .get(base_url + '/c/d_lancaster/' + ak +
            '/dataset_accesses?faculty=2')
            .expectStatus(200)
            .expectHeaderContains('content-type', 'application/json')
            .toss();

        frisby.create('Test dataset_accesses with filter by department')
            .get(base_url + '/c/d_lancaster/' + ak +
            '/dataset_accesses?department=2')
            .expectStatus(200)
            .expectHeaderContains('content-type', 'application/json')
            .toss();

    })
    .toss();
