#!/usr/bin/env lua5.1
-- pure data import tools
package.path = package.path .. ';../openresty/?.lua;'
util = require 'dmao_i_utility'
xml = require 'xml'
lub = require 'lub'
cjson = require 'cjson'
curl = require 'cURL'


local function extract_json(inst, xml_table, et, id_add, id_add_value)
    local data = {}
    lub.search(
        xml_table,
        function(node)
            local include_node = false
            if node.xml == et['element'] then
                local row = {}
                for field, field_value_pair in pairs(et['fields']) do
                    local field_value = field_value_pair[1]
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

-- main
local extract_fields = {
    pure_org_institution = {
        dmao_table = 'institution',
        element = 'a:OrganisationList',
        fields = {
            inst_local_id = {'a:OrganisationID', 'include'},
            name = {'a:OrganisationName', 'include'},
            type = {'a:Type', 'exclude'},
            url = {'a:URL', 'include'}
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
            url = {'a:URL', 'include'}
        },
        want = {
            type = 'department'
        },
        add = {
            faculty_id
        }
    }
}

for _, org_type in ipairs({'pure_org_institution', 'pure_org_faculty'}) do
    local f = assert(io.open('data/pure_orgs.xml'))
    local xml_table = xml.load(f:read'*a')
    local json = extract_json('lancaster', xml_table,
        extract_fields[org_type])
    json_load(extract_fields[org_type]['dmao_table'], json)
    f:close()
end

for _, local_id in ipairs({
    {'2', '5091'},
    {'1', '5096'},
    {'5', '5106'},
    {'3', '5111'},
    {'7', '5137'},
    {'4', '5282'},
    {'6', '5326'}
}) do
    local f = assert(io.open(
        'data/pure_orgs_by_parent_id_' .. local_id[2] .. '.xml'))
    local xml_table = xml.load(f:read'*a')
    local json = extract_json('lancaster', xml_table,
        extract_fields['pure_org_department'], 'faculty_id', local_id[1])
    if not (json == '[]') then
        json_load(extract_fields['pure_org_department']['dmao_table'], json)
    end
    f:close()
end
