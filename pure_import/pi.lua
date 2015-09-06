#!/usr/bin/env lua5.1
-- pure data import tools
package.path = package.path .. ';../openresty/?.lua;'
local util = require 'dmao_i_utility'
local xml = require 'xml'
local lub = require 'lub'
local cjson = require 'cjson'
local curl = require 'cURL'
http = require'socket.http'

environment = 'dev' -- or test or prod


local function extract_json(inst, xml_table, et, id_add, id_add_value)
    local data = {}
    lub.search(
        xml_table,
        function(node)
            local include_node = false
            if node.xml == et['element'] then
                local row = {}
                for field, field_value_pair in pairs(et['fields']) do
                    local field_value = ''
                    if field_value_pair[1] then
                        field_value = field_value_pair[1]
                    end
                    local inc = field_value_pair[2]
                    local value = xml.find(node, field_value)[1]
                    if not value then value = '' end
                    for f, w in pairs(et['want']) do
                        if (f == field) and (w == value) then
                            include_node = true
                        end
                    end
                    if inc == 'include' then
                        row[#row + 1] = '"'
                        row[#row + 1] = field
                        row[#row + 1] = '": '
                        if field_value_pair[3] then
                            value = field_value_pair[3](value)
                        end
                        row[#row + 1] = cjson.encode(util.trim(value))
                        row[#row + 1] = ', '
                    end
                end
                if include_node then
                    local r = {}
                    r[#r + 1] = '{'
                    r[#r + 1] = '"inst_id": '
                    r[#r + 1] = cjson.encode(inst)
                    r[#r + 1] = ','
                    if id_add then
                        r[#r + 1] = '"' .. id_add .. '": '
                                .. cjson.encode(id_add_value) .. ','
                    end
                    r[#r + 1] = string.gsub(table.concat(row), ', $', '')
                    r[#r + 1] = '},'
                    table.insert(data, table.concat(r))
                end
            end
        end
    )
    return '[' .. string.gsub(table.concat(data), ',$', '') .. ']'
end


local function json_load(table, json)
    local load_url = 'http://localhost:8080/dmaonline/v0.3/lancaster/'
            .. table
    local c = curl.easy_init()
    local postdata = {
        name = {
            file = 'anything',
            data = json,
            type = 'application/json'
        }
    }
    c:setopt_url(load_url)
    c:post(postdata)
    c:perform()
end


local function get_json_query(inst, q)
    local get_url = 'http://localhost:8080/dmaonline/v0.3/u/'
            .. inst ..'/' .. q
    local body = http.request(get_url)
    return body
end


local function date_reformat(d)
    local nd
    if not (d == '') then
        local y = string.format('%4d', tonumber(string.sub(d, 7, 10)))
        local m = string.format('%02d', tonumber(string.sub(d, 4, 5)))
        local d = string.format('%02d', tonumber(string.sub(d, 1, 2)))
        nd = y .. '-' .. m .. '-' .. d
    else
        nd = 'null_value'
    end
    return nd
end


-- main
local extract_fields = {
    pure_org_institution = {
        dmao_table = 'institution',
        element = 'a:OrganisationList',
        fields = {
            inst_local_id = {'a:OrganisationID', 'include'},
            name = {'a:OrganisationName', 'include'},
            type = {'a:Type', 'exclude'},
            url = {'a:URL', 'include'},
            description = {'a:SummaryText', 'include'}
        },
        want = {
            type = 'university'
        }
    },
    pure_org_faculty = {
        dmao_table = 'faculty',
        element = 'a:OrganisationList',
        fields = {
            inst_local_id = {'a:OrganisationID', 'include'},
            name = {'a:OrganisationName', 'include'},
            type = {'a:Type', 'exclude'},
            url = {'a:URL', 'include' },
            description = {'a:SummaryText', 'include'}
        },
        want = {
            type = 'faculty'
        }
    },
    pure_org_department = {
        dmao_table = 'department',
        element = 'a:OrganisationList',
        fields = {
            inst_local_id = {'a:OrganisationID', 'include'},
            name = {'a:OrganisationName', 'include'},
            type = {'a:Type', 'exclude'},
            url = {'a:URL', 'include'},
            description = {'a:SummaryText', 'include'}
        },
        want = {
            type = 'department'
        },
        add = {
            faculty_id
        }
    },
    pure_publication = {
        dmao_table = 'publication',
        element = 'a:PublicationList',
        fields = {

        }
    },
    pure_project = {
        dmao_table = 'project',
        element = 'a:Project',
        fields = {
            project_name = {'a:Title', 'include'},
            project_acronym = {'a:Acronym', 'include'},
            description = {'a:Description', 'include'},
            institution_project_code = {'a:ProjectID', 'include'},
            type = {'a:Type', 'exclude'},
            -- lead_faculty_id = '',
            -- lead_department_id = '',
            project_start = {'a:StartDate', 'include', date_reformat},
            project_end = {'a:EndDate', 'include', date_reformat},
            inst_url = {'a:InternalURL', 'include'},
        },
        want = {
            type = 'Projects'
        }
    }
}

for _, org_type in ipairs({'pure_org_institution', 'pure_org_faculty'}) do
    local f = assert(io.open('data/pure_orgs.xml'))
    local xml_table = xml.load(f:read'*a')
    local json = extract_json('lancaster', xml_table,
        extract_fields[org_type])
    if not (json== '[]') then
        json_load(extract_fields[org_type]['dmao_table'], json)
    end
    f:close()
end

-- get a mapping of pure faculty ids to dmao faculty ids
local q = 'u_dmao_faculty_ids_inst_ids_map'
local json = get_json_query('lancaster', q)
local f_map = cjson.decode(json)

-- load departments by faculty
for _, lf in pairs(f_map) do
    local f_id, lf_id = lf['faculty_id'], lf['inst_local_id']
    local f = assert(io.open(
        'data/pure_orgs_by_parent_id_' .. lf_id .. '.xml'))
    local xml_table = xml.load(f:read'*a')
    local json = extract_json('lancaster', xml_table,
        extract_fields['pure_org_department'], 'faculty_id', f_id)
    if not (json == '[]') then
        json_load(extract_fields['pure_org_department']['dmao_table'], json)
    end
    f:close()
end

-- load projects
local f = assert(io.open('data/pure_projects.xml'))
local xml_table = xml.load(f:read'*a')
local json = extract_json('lancaster', xml_table,
        extract_fields['pure_project'])
if not (json== '[]') then
    json_load(extract_fields['pure_project']['dmao_table'], json)
end
f:close()

local q = 'u_dmao_department_ids_faculty_ids_map'
local json = get_json_query('lancaster', q)
local d_map = cjson.decode(json)

-- load publications by faculty, department
for x, y in pairs(d_map) do
    print(x, y['department_id'], y['faculty_id'], y['local_faculty_id'], y['dept_name'])
end
