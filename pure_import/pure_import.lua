#!/usr/bin/env lua5.1

package.path = package.path .. ';../openresty/?.lua;../lualib/?.lua;' ..
    '/usr/local/share/lua/5.1/?/init.lua;/usr/local/share/lua/5.1/?.lua;'
require 'luarocks.loader'
util = require 'dmao_i_utility_jhk_dev'
local inspect = require 'inspect'
local xpath = require 'xpath'
local lom = require 'lxp.lom'
local http = require 'socket.http'
local lfs = require 'lfs'
local curl = require 'cURL'
local cjson = require 'cjson'


local debug_flag = false
local progress_print = true
local save_xml = true
local saved_xml_counter = 0

local load_port = '8070'
-- print inspection
local function pi(n)
    print(inspect.inspect(n))
end

local upp_placeholder = '##upp_placeholder##'
local current_institution = ''

local function get_upp()
    dofile('connection_pure.lua')
    return connection_pure[current_institution]
end

-- given the start and end date, create a date range string in postgres
-- format '[start_date, end_date)'
local function make_date_range(args)
    local start_date = args[1]
    local end_date = args[2]
    local t = {}
    t[#t + 1] = '['
    t[#t + 1] = start_date
    t[#t + 1] = ','
    t[#t + 1] = end_date
    t[#t + 1] = ')'
    return(table.concat(t))
end

local function make_funder_id(args)
    return current_institution .. ':' .. args[1]
end

local extract_variables = {
    pure = {
        count_tag = 'core:count',
        result_tag = 'core:result',
        content_tag = 'core:content',
        pure_datasets = {
            xpb = '/dataset:GetDataSetsResponse',
            xpcb = '/dataset:GetDataSetsResponse/core:result/core:content'
        },
        pure_faculties = {
            xpb = '/organisation-template:GetOrganisationResponse',
            xpcb = '/organisation-template:GetOrganisationResponse' ..
                '/core:result/core:content'
        },
        pure_departments = {
            xpb = '/organisation-template:GetOrganisationResponse',
            xpcb = '/organisation-template:GetOrganisationResponse' ..
                '/core:result/core:content'
        },
        pure_external_funders = {
            xpb = '/externalorganisation-template:' ..
                'GetExternalOrganisationResponse',
            xpcb = '/externalorganisation-template:' ..
                'GetExternalOrganisationResponse/core:result/core:content'
        },
        pure_projects = {
            xpb = '/project-template:GetProjectResponse',
            xpcb = '/project-template:GetProjectResponse' ..
                '/core:result/core:content'
        },
        pure_publications = {
            xpb = '/publication-template:GetPublicationResponse',
            xpcb = '/publication-template:GetPublicationResponse' ..
                '/core:result/core:content'
        }
    }
}

local institutional_variables = {
    lancaster = {
        pure_url = 'http://' .. upp_placeholder .. 'pure.lancs.ac.uk/ws/rest',
        faculties_url = 'http://' .. upp_placeholder ..
            'pure.lancs.ac.uk/ws/rest' ..
            '/organisation?typeClassificationUris.uri=' ..
            '/dk/atira/pure/organisation/organisationtypes/organisation' ..
            '/faculty&rendering=xml_long'
    },
    birmingham = {
        pure_url = 'http://' .. upp_placeholder ..
            'pure-oai.bham.ac.uk/ws/rest',
        faculties_url = 'http://' .. upp_placeholder ..
            'pure-oai.bham.ac.uk/ws/rest' ..
            '/organisation?typeClassificationUris.uri=' ..
            '/dk/atira/pure/organisation/organisationtypes/organisation' ..
            '/school&rendering=xml_long',
    },
    york = {
        pure_url = 'http://' .. upp_placeholder .. 'pure.york.ac.uk/ws/rest',
        faculties_url = 'http://' .. upp_placeholder ..
            'pure.york.ac.uk/ws/rest' ..
            '/organisation?typeClassificationUris.uri=' ..
            '/dk/atira/pure/organisation/organisationtypes/organisation' ..
            '/school&rendering=xml_long',
    }
}

local extract_parameters = {
    pure_datasets = {
        window_size = 20,
        extract_name = 'Pure datasets',
        url = '/datasets?rendering=xml_long&managingOrganisationUuids.uuid=',
        birmingham_all_datasets_url = '/datasets?rendering=xml_long',
        count_tag = extract_variables['pure']['count_tag'],
        result_tag = extract_variables['pure']['result_tag'],
        content_tag = extract_variables['pure']['content_tag'],
        count_xpath = extract_variables['pure']['pure_datasets']['xpb'] ..
                '/' .. extract_variables['pure']['count_tag'],
        content_xpath = extract_variables['pure']['pure_datasets']['xpcb'],
        retrieved_fields = {
            uuid = {
                xpath = extract_variables['pure']['pure_datasets']['xpcb']
            },
            name = {
                xpath = extract_variables['pure']['pure_datasets']['xpcb'] ..
                    '/stab:title/core:localizedString'
            },
            description = {
                xpath = extract_variables['pure']['pure_datasets']['xpcb'] ..
                    '/stab:descriptions' ..
                    '/extensions-core:classificationDefinedField' ..
                    '/extensions-core:value/core:localizedString'
            },
            doi = {
                xpath = extract_variables['pure']['pure_datasets']['xpcb'] ..
                    '/stab:dois/core:doi/core:doi'
            },
            filename = {
                xpath = extract_variables['pure']['pure_datasets']['xpcb'] ..
                    '/stab:documents/extensions-core:document/core:fileName'
            },
            filesize = {
                xpath = extract_variables['pure']['pure_datasets']['xpcb'] ..
                    '/stab:documents/extensions-core:document/core:size'
            },
            fileurl = {
                xpath = extract_variables['pure']['pure_datasets']['xpcb'] ..
                    '/stab:documents/extensions-core:document/core:url'
            },
            mimetype = {
                xpath = extract_variables['pure']['pure_datasets']['xpcb'] ..
                    '/stab:documents/extensions-core:document/core:mimeType'
            },
            create_date = {
                xpath = extract_variables['pure']['pure_datasets']['xpcb'] ..
                    '/core:created'
            }
        },
        table = 'dataset',
        load_url = 'http://localhost:' .. load_port .. '/dmaonline/v0.3',
        table_map = {
            dataset_create_date = 'create_date',
            dataset_notes = 'description',
            dataset_pid = 'doi',
            dataset_filename = 'filename',
            dataset_size = 'filesize',
            dataset_link = 'fileurl',
            dataset_format = 'mimetype',
            dataset_name = 'name',
            dataset_local_inst_id = 'uuid',
        }
    },
    pure_faculties = {
        window_size = 20,
        extract_name = 'Pure faculties',
        count_tag = extract_variables['pure']['count_tag'],
        result_tag = extract_variables['pure']['result_tag'],
        content_tag = extract_variables['pure']['content_tag'],
        count_xpath = extract_variables['pure']['pure_faculties']['xpb'] ..
            '/' .. extract_variables['pure']['count_tag'],
        content_xpath = extract_variables['pure']['pure_faculties']['xpcb'],
        retrieved_fields = {
            uuid = {
                xpath = extract_variables['pure']['pure_faculties']['xpcb']
            },
            name = {
                xpath = extract_variables['pure']['pure_faculties']['xpcb'] ..
                    '/stab1:name/core:localizedString'
            },
            abbrev = {
                xpath = extract_variables['pure']['pure_faculties']['xpcb'] ..
                    '/stab1:nameVariant' ..
                    '/core:classificationDefinedFieldExtension/core:value' ..
                    '/core:localizedString',
            },
            url = {
                xpath = extract_variables['pure']['pure_faculties']['xpcb'] ..
                    '/stab1:webAddresses' ..
                    '/core:classificationDefinedFieldExtension/core:value' ..
                    '/core:localizedString'
            },
            description = {
                xpath = extract_variables['pure']['pure_faculties']['xpcb'] ..
                    '/stab1:profileInformation' ..
                    '/extensions-core:customField' ..
                    '/extensions-core:value/core:localizedString'
            }
        },
        table = 'faculty',
        load_url = 'http://localhost:' .. load_port .. '/dmaonline/v0.3',
        table_map = {
            name = 'name',
            inst_local_id = 'uuid',
            abbreviation = 'abbrev',
            url = 'url',
            description = 'description'
        }
    },
    pure_departments = {
        window_size = 20,
        extract_name = 'Pure departments',
        url = '/organisation?rendering=xml_long&typeClassificationUris.uri=' ..
            '/dk/atira/pure/organisation/organisationtypes/organisation' ..
            '/department&parentUuids.uuid=',
        count_tag = extract_variables['pure']['count_tag'],
        result_tag = extract_variables['pure']['result_tag'],
        content_tag = extract_variables['pure']['content_tag'],
        count_xpath = extract_variables['pure']['pure_departments']['xpb'] ..
            '/' .. extract_variables['pure']['count_tag'],
        content_xpath = extract_variables['pure']['pure_departments']['xpcb'],
        retrieved_fields = {
            uuid = {
                xpath = extract_variables['pure']['pure_departments']['xpcb']
            },
            name = {
                xpath = extract_variables['pure']['pure_departments']['xpcb'] ..
                    '/stab1:name/core:localizedString'
            },
            abbrev = {
                xpath = extract_variables['pure']['pure_departments']['xpcb'] ..
                    '/stab1:nameVariant' ..
                    '/core:classificationDefinedFieldExtension/core:value' ..
                    '/core:localizedString',
            },
            url = {
                xpath = extract_variables['pure']['pure_departments']['xpcb'] ..
                    '/stab1:webAddresses' ..
                    '/core:classificationDefinedFieldExtension/core:value' ..
                    '/core:localizedString'
            },
            description = {
                xpath = extract_variables['pure']['pure_departments']['xpcb'] ..
                    '/stab1:profileInformation' ..
                    '/extensions-core:customField' ..
                    '/extensions-core:value/core:localizedString'
            }
        },
        table = 'department',
        load_url = 'http://localhost:' .. load_port .. '/dmaonline/v0.3',
        table_map = {
            name = 'name',
            inst_local_id = 'uuid',
            abbreviation = 'abbrev',
            url = 'url',
            description = 'description'
        }
    },
    pure_external_funders = {
        window_size = 20,
        extract_name = 'Pure external funders',
        url = '/externalorganisation?typeClassificationUris.uri=' ..
            '/dk/atira/pure/ueoexternalorganisation/' ..
            'ueoexternalorganisationtypes/ueoexternalorganisation' ..
            '/fundingbody' ..
            '&rendering=xml_long',
        count_tag = extract_variables['pure']['count_tag'],
        result_tag = extract_variables['pure']['result_tag'],
        content_tag = extract_variables['pure']['content_tag'],
        count_xpath = extract_variables['pure']['pure_external_funders']['xpb']
            .. '/' .. extract_variables['pure']['count_tag'],
        content_xpath =
            extract_variables['pure']['pure_external_funders']['xpcb'],
        retrieved_fields = {
            uuid = {
                xpath = extract_variables['pure']['pure_external_funders']
                    ['xpcb']
            },
            name = {
                xpath = extract_variables['pure']['pure_external_funders']
                    ['xpcb'] ..
                    '/stab:name'
            },
            alt_name = {
                xpath = extract_variables['pure']['pure_external_funders']
                    ['xpcb'] ..
                    '/stab:alternativeNames/stab:alternativeName'
            }
        },
        table = 'funder',
        load_url = 'http://localhost:' .. load_port .. '/dmaonline/v0.3',
        table_map = {
            name = 'name',
            inst_alt_name = 'alt_name',
            inst_local_id = 'uuid',
            funder_id = {
                fn = make_funder_id,
                args = {
                    'uuid'
                }
            }
        }
    },
    pure_projects = {
        window_size = 20,
        extract_name = 'Pure projects',
        url = '/project?rendering=xml_long&createdDate.fromDate=2015-01-01' ..
            '&owningOrganisationUuids.uuid=',
        count_tag = extract_variables['pure']['count_tag'],
        result_tag = extract_variables['pure']['result_tag'],
        content_tag = extract_variables['pure']['content_tag'],
        count_xpath = extract_variables['pure']['pure_projects']['xpb'] ..
            '/' .. extract_variables['pure']['count_tag'],
        content_xpath = extract_variables['pure']['pure_projects']['xpcb'],
        retrieved_fields = {
            uuid = {
                xpath = extract_variables['pure']['pure_projects']['xpcb']
            },
            name = {
                xpath = extract_variables['pure']['pure_projects']['xpcb'] ..
                    '/stab1:title/core:localizedString'

            },
            description = {
                xpath = extract_variables['pure']['pure_projects']['xpcb'] ..
                '/stab1:description/core:localizedString'
            },
            url = {
                xpath = extract_variables['pure']['pure_projects']['xpcb'] ..
                    '/stab1:projectURL'
            },
            start_date = {
                xpath = extract_variables['pure']['pure_projects']['xpcb'] ..
                    '/stab1:startFinishDate/extensions-core:startDate'
            },
            end_date = {
                xpath = extract_variables['pure']['pure_projects']['xpcb'] ..
                    '/stab1:startFinishDate/extensions-core:endDate'
            },
            type = {
                xpath = extract_variables['pure']['pure_projects']['xpcb'] ..
                    '/stab1:typeClassification/core:uri'

            },
            status = {
                xpath = extract_variables['pure']['pure_projects']['xpcb'] ..
                    '/stab1:status/core:term/core:localizedString'
            },
            classification = {
                xpath = extract_variables['pure']['pure_projects']['xpcb'] ..
                    '/stab1:typeClassification/core:term/core:localizedString'
            },
            acronym = {
                xpath = extract_variables['pure']['pure_projects']['xpcb'] ..
                    '/stab:acronym'
            },
            inst_project_code = {
                xpath = extract_variables['pure']['pure_projects']['xpcb'] ..
                    '/stab1:external/extensions-core:sourceId'
            }
        },
        table = 'project',
        load_url = 'http://localhost:' .. load_port .. '/dmaonline/v0.3',
        table_map = {
            project_name = 'name',
            inst_local_id = 'uuid',
            project_acronym = 'abbrev',
            inst_url = 'url',
            description = 'description',
            institution_project_code = 'inst_project_code',
            inst_project_classification = 'classification',
            inst_project_status = 'status',
            inst_project_type = 'type',
            project_date_range = {
                fn = make_date_range,
                args = {
                    'start_date',
                    'end_date'
                }
            }
        }
    },
    pure_publications = {
        window_size = 1,
        extract_name = 'Pure publications',
        url = '/publication?rendering=xml_long&' ..
            'publicationDate.fromDate=2015-01-01&' ..
            'owningOrganisationUuids.uuid=',
        count_tag = extract_variables['pure']['count_tag'],
        result_tag = extract_variables['pure']['result_tag'],
        content_tag = extract_variables['pure']['content_tag'],
        count_xpath = extract_variables['pure']['pure_publications']['xpb'] ..
            '/' .. extract_variables['pure']['count_tag'],
        content_xpath = extract_variables['pure']['pure_publications']['xpcb'],
        retrieved_fields = {
            uuid = {
                xpath = extract_variables['pure']['pure_publications']['xpcb']
            },
            title = {
                xpath = extract_variables['pure']['pure_publications']
                    ['xpcb'] ..
                    '/publication-base_uk:title'
            },
            abstract = {
                xpath = extract_variables['pure']['pure_publications']
                    ['xpcb'] ..
                    '/publication-base_uk:abstract/core:localizedString'
            },
            doi = {
                xpath = extract_variables['pure']['pure_publications']
                    ['xpcb'] ..
                    '/publication-base_uk:dois/core:doi/core:doi'
            },
            year = {
                xpath = extract_variables['pure']['pure_publications']
                    ['xpcb'] ..
                    '/publication-base_uk:publicationDate/core:year'
            },
            month = {
                xpath = extract_variables['pure']['pure_publications']
                    ['xpcb'] ..
                    '/publication-base_uk:publicationDate/core:month'
            },
            day = {
                xpath = extract_variables['pure']['pure_publications']
                    ['xpcb'] ..
                    '/publication-base_uk:publicationDate/core:day'
            },
            pub_status = {
                xpath = extract_variables['pure']['pure_publications']
                    ['xpcb'] ..
                    '/publication-base_uk:publicationStatus/core:uri'
            },
            pub_type = {
                xpath = extract_variables['pure']['pure_publications']
                    ['xpcb'] ..
                    '/publication-base_uk:typeClassification/core:uri'
            }
        },
        table = 'publication',
        load_url = 'http://localhost:' .. load_port .. '/dmaonline/v0.3',
        table_map = {
            cris_id = 'uuid',
            publication_pid = 'doi',
            inst_pub_title = 'title',
            inst_pub_abstract = 'abstract',
            inst_pub_year = 'year',
            inst_pub_month = 'month',
            inst_pub_day = 'day',
            inst_pub_status = 'status',
            inst_pub_type = 'type'
        }
    }
}

local function get_xml_file(f)
    local fd = assert(io.open(f))
    return lom.parse((fd:read'*a'))
end

local function get_json_query(inst, q)
    local get_url = 'http://localhost:' .. load_port .. '/dmaonline/v0.3/u/'
        .. inst ..'/' .. q
    local body = http.request(get_url)
    return body
end

local function perform_json_load(table, load_url, api_key, json)
    local lu = load_url .. '/' .. api_key .. '/' .. table
    local c = curl.easy_init()
    local postdata = {
        name = {
            file = 'anything',
            data = json,
            type = 'application/json'
        }
    }
    local t = {}
    c:setopt_url(lu)
    c:post(postdata)
    c:setopt(curl.OPT_WRITEFUNCTION, function (a, b)
        local s
        if type(a) == "string" then s = a else s = b end
        t[#t + 1] = s
        return #s
    end)
    assert(c:perform())
    return(t)
end

local function json_loader(table, load_url, api_key, json)
    local r = perform_json_load(table, load_url, api_key, json)
    if (string.find(r[1], 'affected_rows')) == 3 then
        return(r[1])
    else
        print(r[1])
        return(r[1])
    end
end

local function make_json(data_table, map, additional_fields)
    local json_table = {}
    json_table[#json_table + 1] = '['
    for index, d in pairs(data_table) do
        local r = {}
        r[#r + 1] = '{'
        if not (additional_fields == nil) then
            for k, v in pairs(additional_fields) do
                r[#r + 1] = '"' .. k .. '": '
                r[#r + 1] = cjson.encode(v)
                r[#r + 1] = ','
            end
        end
        for k, o in pairs(map) do
            r[#r + 1] = '"'
            r[#r + 1] = k
            r[#r + 1] = '":'
            if type(o) == 'table' then
                -- this contains a function to be applied
                local fn = o['fn']
                local arg_list = {}
                for fak, fav in ipairs(o['args']) do
                    table.insert(arg_list, d[fav])
                end
                local fr = fn(arg_list)
                r[#r + 1] = cjson.encode(fr)
            else
                r[#r + 1] = cjson.encode(d[o])
            end
            r[#r + 1] = ','
        end
        r[#r + 1] = '}'
        local rs = table.concat(r)
        rs = string.gsub(rs, ':null', ':"null_value"')
        rs = string.gsub(rs, ',}$', '}')
        json_table[#json_table + 1] = rs
        json_table[#json_table + 1] = ','
    end
    json_table[#json_table] = string.gsub(json_table[#json_table], ',$', '')
    json_table[#json_table + 1] = ']'
    return(table.concat(json_table))
end

local function get_xml_url(u)
    --if progress_print then print(u) end
    local resp = {}
    local res, code, headers, status = http.request
        {
            method = 'GET', url = u, headers = {},
            sink = ltn12.sink.table(resp)
        }
    if code == 200 then
        if not save_xml then
            return lom.parse(table.concat(resp))
        else
            local xml = table.concat(resp)
            local d = 'saved_xml/'
            lfs.mkdir(d)
            saved_xml_counter = saved_xml_counter + 1
            local f = d .. 'f_' .. saved_xml_counter .. '.xml'
            local fd = io.open(f, 'w')
            fd:write(xml)
            fd:close()
            io.flush()
            os.execute("xmllint --format - < " .. f .. ' > ' ..
                d .. 'xx.tmp; mv ' .. d .. 'xx.tmp ' .. f)
            return lom.parse(xml)
        end
    else
        return nil
    end
end

local function split_string(str, delimiter)
    if delimiter == nil then
        delimiter = "%s"
    end
    local t={}
    for s in string.gmatch(str, "([^" .. delimiter .. "]+)") do
        t[#t + 1] = s
    end
    return t
end

local function extract_field_from_content_node(
        content_node, content_xpath,
        field_xpath, sfxp
    )
    local relative_field_xpath
    local split_field_xpath
    if sfxp == nil then
        relative_field_xpath = string.gsub(field_xpath, '^' ..
            string.gsub(content_xpath, '%-', '%%-') .. '/', '')
        split_field_xpath = split_string(relative_field_xpath, '/')
    else
        split_field_xpath = sfxp
    end
    local field_value
    for _, v_content in pairs(content_node) do
        if (v_content['tag'] == split_field_xpath[1]) then
            if #split_field_xpath == 1 then -- the end of the xpath expression
                return v_content[1]
            else -- dive deeper in
                table.remove(split_field_xpath, 1)
                return extract_field_from_content_node(
                    v_content, nil, nil, split_field_xpath)
            end
        end
    end
end

local function pure_collector(u, object)
    local data_table = {}
    local xml_table = get_xml_url(u)
    if not (xml_table == nil) then
        local count_xpath = object['count_xpath']
        local content_xpath = object['content_xpath']
        local rec_count = xpath.selectNodes(xml_table, count_xpath)[1]
        local num_records
        if rec_count['tag'] == object['count_tag'] then
            num_records = rec_count[1]
        end
        local content_nodes = xpath.selectNodes(xml_table, content_xpath)
        for _, content_node in pairs(content_nodes) do
            local dt_entry = {}
            for rk, retrieve_field in pairs(object['retrieved_fields']) do
                local xpath = retrieve_field['xpath']
                if content_node['tag'] == object['content_tag'] then
                    if rk == 'uuid' then
                        dt_entry[rk] = content_node['attr']['uuid']
                else
                        dt_entry[rk] = extract_field_from_content_node(content_node,
                            content_xpath, xpath)
                    end
                end
            end
            table.insert(data_table, dt_entry)
        end
        return 0, num_records + 0, data_table
    else
        return 1, 0, {}
    end
end

local function get_faculty_id (map, u)
    for _, v in pairs(map) do
        if v['inst_local_id'] == u then
            return v['faculty_id']
        end
    end
end

local function collect_from_pure(url, object, arg)
    local data_table = {}
    local window_size, window_offset = object['window_size'], 0
    local dt, nr = {}, 9999
    local collected_so_far = 0
    local current_fetch_url
    local pc_rc
    while collected_so_far < nr do
        if arg == nil then
            current_fetch_url =  url .. '&window.size=' ..
                window_size .. '&window.offset=' .. window_offset
        else
            current_fetch_url =  url .. arg .. '&window.size=' ..
                window_size .. '&window.offset=' .. window_offset
        end
        local current_nr = nr
        pc_rc, nr, dt = pure_collector(current_fetch_url, object)
        if (nr == 0) and (pc_rc == 1) then
            nr = current_nr - window_size
        else
            if not (current_nr == 9999) then
                nr = current_nr
            end
        end
        collected_so_far = collected_so_far + #dt
        if progress_print then
            print(current_institution .. ' : Collected ' .. collected_so_far ..
                ' for ' .. object['extract_name'])
        end
        window_offset = window_offset + window_size
        for k, _ in pairs(dt) do
            table.insert(data_table, dt[k])
        end
    end
    if progress_print then
        print(current_institution .. ' : Collected ' .. #data_table .. ' records for '
            .. object['extract_name'])
    end
    return #data_table, data_table
end

local function get_api_key(inst)
    local json = get_json_query(inst, 'u_api_key_for_inst')
    return cjson.decode(json)[1]['api_key']
end

local function populate_url(u, p)
    return string.gsub(u, upp_placeholder, p)
end

-- main

local institutions = {
    'lancaster',
    'birmingham',
    --'york'
}

--for _, inst in pairs(institutions) do
--    current_institution = inst
--    local url
--    local api_key = get_api_key(inst)
--    -- first extract the funder list
--    local url = populate_url(institutional_variables[inst]['pure_url'] ..
--        extract_parameters['pure_external_funders']['url'], get_upp())
--    local num_records, pure_external_funders =
--    collect_from_pure(url, extract_parameters['pure_external_funders'])
--    local json = make_json(pure_external_funders,
--        extract_parameters['pure_external_funders']['table_map'],
--        {
--            inst_id = inst
--        })
--    local r = json_loader(extract_parameters['pure_external_funders']['table'],
--        extract_parameters['pure_external_funders']['load_url'] .. '/' .. inst,
--        api_key,
--        json)
--
--    -- next, extract the faculties
--    url = populate_url(institutional_variables[inst]['faculties_url'],
--        get_upp())
--    local num_records, pure_faculties =
--        collect_from_pure(url, extract_parameters['pure_faculties'])
--    local json = make_json(
--        pure_faculties,
--        extract_parameters['pure_faculties']['table_map'],
--        {
--            inst_id = inst
--        })
--    local r = json_loader(
--        extract_parameters['pure_faculties']['table'],
--        extract_parameters['pure_faculties']['load_url'] .. '/' .. inst,
--        api_key,
--        json
--    )
--
--    local json = get_json_query(inst, 'u_dmao_faculty_ids_inst_ids_map')
--    local f_map = cjson.decode(json)
--
--    -- now we have the faculties, extract departments
--    for _, v in pairs(pure_faculties) do
--        local faculty_uuid = v['uuid']
--        url = populate_url(institutional_variables[inst]['pure_url'] ..
--            extract_parameters['pure_departments']['url'], get_upp())
--        local num_records, pure_departments =
--            collect_from_pure(url, extract_parameters['pure_departments'],
--                faculty_uuid)
--        if num_records > 0 then
--            local faculty_name = v['name']
--            for k, department in pairs(pure_departments) do
--                local sd = {}
--                table.insert(sd, department)
--                local faculty_id = get_faculty_id(f_map, faculty_uuid)
--                local json = make_json(
--                    sd,
--                    extract_parameters['pure_departments']['table_map'],
--                    {
--                        inst_id = inst,
--                        faculty_id = faculty_id
--                    })
--                local r = json_loader(
--                    extract_parameters['pure_departments']['table'],
--                    extract_parameters['pure_departments']['load_url'] ..
--                        '/' .. inst,
--                    api_key,
--                    json
--                )
--            end
--        end
--    end
--    -- now for each department find projects, datasets, publications
--    -- by department
--    local json = get_json_query(inst, 'u_dmao_department_ids_faculty_ids_map')
--    local d_map = cjson.decode(json)
--    for k, v in ipairs(d_map) do
--        local pure_dept_uuid = v['local_department_id']
--        local dmao_dept_id = v['department_id']
--        local dmao_faculty_id = v['faculty_id']
--        local dept_name = v['dept_name']
--
--        -- for each department collect it's projects
--        url = populate_url(institutional_variables[inst]['pure_url'] ..
--            extract_parameters['pure_projects']['url'] .. pure_dept_uuid,
--            get_upp())
--        local num_records, pure_projects =
--            collect_from_pure(url, extract_parameters['pure_projects'])
--        print('projects', dept_name, num_records)
--        if num_records > 0 then
--            local json = make_json(pure_projects,
--                extract_parameters['pure_projects']['table_map'],
--                {
--                    inst_id = inst,
--                    lead_faculty_id = dmao_faculty_id,
--                    lead_department_id = dmao_dept_id
--                })
--            local r = json_loader(extract_parameters['pure_projects']['table'],
--                extract_parameters['pure_projects']['load_url'] .. '/' .. inst,
--                api_key,
--                json)
--        end
--
--        -- for each department collect it's datasets
--        url = populate_url(institutional_variables[inst]['pure_url'] ..
--            extract_parameters['pure_datasets']['url'] .. pure_dept_uuid,
--            get_upp())
--        local num_records, pure_datasets =
--            collect_from_pure(url, extract_parameters['pure_datasets'])
--        print('datasets', dept_name, num_records)
--        if num_records > 0 then
--            for _, dataset in pairs(pure_datasets) do
--                local sd = {}
--                table.insert(sd, dataset)
--                local json = make_json(sd,
--                    extract_parameters['pure_datasets']['table_map'],
--                    {
--                        inst_id = inst,
--                        lead_faculty_id = dmao_faculty_id,
--                        lead_department_id = dmao_dept_id
--                    })
--                local r = json_loader(extract_parameters['pure_datasets']['table'],
--                    extract_parameters['pure_datasets']['load_url'] .. '/' .. inst,
--                    api_key,
--                    json)
--            end
--        end
--
--        -- for each department collect it's publications from 2015 on, on
--        -- the assumption that only only stuff moving forwards might have
--        -- an associated managed dataset
--        url = populate_url(institutional_variables[inst]['pure_url'] ..
--            extract_parameters['pure_publications']['url'] .. pure_dept_uuid,
--            get_upp())
--        local num_records, pure_publications =
--            collect_from_pure(url, extract_parameters['pure_publications'])
--        print('publications', dept_name, num_records)
--        if num_records > 0 then
--            local json = make_json(pure_publications,
--                extract_parameters['pure_publications']['table_map'],
--                {
--                    inst_id = inst,
--                    lead_faculty_id = dmao_faculty_id,
--                    lead_department_id = dmao_dept_id
--                })
--            local r = json_loader(extract_parameters['pure_publications']['table'],
--                extract_parameters['pure_publications']['load_url'] .. '/' .. inst,
--                api_key,
--                json)
--        end
--    end
--end


-- get all datasets from birmingham, all but three are not associated with
-- a department
local inst = 'birmingham'
current_institution = inst
local api_key = get_api_key(inst)
-- for each department collect it's datasets
local url = populate_url(institutional_variables[inst]['pure_url'] ..
    extract_parameters['pure_datasets']['birmingham_all_datasets_url'],
    get_upp())
local num_records, pure_datasets =
    collect_from_pure(url, extract_parameters['pure_datasets'])
if num_records > 0 then
    for _, dataset in pairs(pure_datasets) do
        local sd = {}
        table.insert(sd, dataset)
        local json = make_json(sd,
            extract_parameters['pure_datasets']['table_map'],
            {
                inst_id = inst,
            })
        local r = json_loader(extract_parameters['pure_datasets']['table'],
            extract_parameters['pure_datasets']['load_url'] .. '/' .. inst,
            api_key,
            json)
    end
end
