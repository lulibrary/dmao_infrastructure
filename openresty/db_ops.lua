
cjson = require 'cjson'
upload = require 'resty.upload'
pg = require 'pgmoon'

debug = true
debug = false

-- TODO: Needs some work to make this generic

-- iterate through a lua table to print via nginx, for debugging purposes.
function tprint (tbl, indent)
    if not indent then indent = 4 end
    for k, v in pairs(tbl) do
        local formatting = string.rep('  ', indent) .. k .. ': '
        if type(v) == 'table' then
            ngx.say(formatting)
            tprint(v, indent + 1)
        elseif type(v) == 'boolean' then
            ngx.say(formatting .. tostring(v))
        else
            ngx.say(formatting .. v)
        end
    end
end


-- put json data from form into lua table
function form_to_table()
    local form, err = upload:new(8192)
    if not form then
        ngx.log(ngx.ERR, "failed to upload:new -  ", err)
        ngx.exit(500)
    end
    form:set_timeout(2000) -- 2 seconds
    while true do
        local typ, res, err = form:read()
        if not typ then
            ngx.say("failed to form:read - ", err)
            return
        end
        if typ == 'body' then
            local j = cjson.decode(res)
            if type(j) == 'table' then
                return j
            end
        end
        if typ == 'eof'
        then
            break
        end
    end
end


-- get the database username and password
function get_connection_details()
    local f = "/usr/local/openresty/lualib/connection.conf"
    dofile(f)
    return user, passwd
end


-- open a database connection
function open_dmaonline_db()
    local u, p = get_connection_details()
    local d = pg.new(
        {
            host="127.0.0.1",
            port="5432",
            database="DMAonline",
            user=u, password=p
        }
    )
    assert(d:connect())
    return d
end


-- close the database connection
function close_dmaonline_db(c)
    assert(c:disconnect())
end

function db_operation(d, q)
    if debug then
        ngx.say(q)
    else
        local res = assert(d:query(q))
        ngx.say(cjson.encode(res))
        -- TODO: Make sure correct HTTP headers are being returned
    end
end

-- institution database operations
function d_institution(inst, operation, val)
    local db = open_dmaonline_db()
    local query = ""
    if operation == "insert" then
        local values = db:escape_literal(val['inst_id']) .. ', '
        values = values .. db:escape_literal(val['name']) .. ', '
        values = values .. db:escape_literal(val['contact']) .. ', '
        values = values .. db:escape_literal(val['contact_phone']) .. ', '
        values = values .. db:escape_literal(val['contact_email']) .. ', '
        values = values .. db:escape_literal(val['cris_sys']) .. ', '
        values = values .. db:escape_literal(val['pub_sys']) .. ', '
        values = values .. db:escape_literal(val['dataset_sys']) .. ', '
        values = values .. db:escape_literal(val['archive_sys']) .. ', '
        values = values .. db:escape_literal(val['currency']) .. ', '
        values = values .. db:escape_literal(val['currency_symbol'])
        query = "insert into institution values ("
                  .. values .. ") returning *;"
    elseif operation == "update" then
        query = "update institution"
    elseif operation == "delete" then
        query = "delete from institution where inst_id = "
            .. db:escape_literal(inst) .. ";"
    else
        ngx.say("Invalid operation, " .. operation .. " on institution")
    end
    db_operation(db, query)
    close_dmaonline_db(db)
end


-- faculty database operations
function d_faculty(inst, operation, val)
    local db = open_dmaonline_db()
    local values = ""
    local query = ""
    ngx.say("d_faculty " .. operation .. " for " .. inst)
    for _, v in pairs(val) do
        values = values .. "(" .. db:escape_literal(v['inst_id']) .. ', '
        values = values .. db:escape_literal(v['name']) .. ', '
        values = values .. db:escape_literal(v['abbreviation']) .. "), "
    end
    values = string.gsub(values, ", $", "")
    query = "insert into faculty(inst_id, name, abbreviation) values "
            .. values .. " returning *;"
    db_operation(db, query)
    close_dmaonline_db(db)
end


-- funder database operations
function d_funder(inst, operation, val)
    ngx.say("d_funder " .. operation .. " for " .. inst)
    tprint(val)
end


-- funder_dmp_states database operations
function d_funder_dmp_states(inst, operation, val)
    ngx.say("d_funder_dmp_states " .. operation .. " for " .. inst)
    tprint(val)
end


-- department database operations
function d_department(inst, operation, val)
    ngx.say("d_department " .. operation .. " for " .. inst)
    tprint(val)
end


-- storage_costs database operations
function d_storage_costs(inst, operation, val)
    ngx.say("d_storage_costs " .. operation .. " for " .. inst)
    tprint(val)
end


-- dataset database operations
function d_dataset(inst, operation, val)
    ngx.say("d_dataset " .. operation .. " for " .. inst)
    tprint(val)
end


-- dataset_accesses database operations
function d_dataset_accesses(inst, operation, val)
    ngx.say("d_dataset_accesses " .. operation .. " for " .. inst)
    tprint(val)
end


-- publication database operations
function d_publication(inst, operation, val)
    ngx.say("d_publication " .. operation .. " for " .. inst)
    tprint(val)
end


-- project database operations
function d_project(inst, operation, val)
    ngx.say("d_project " .. operation .. " for " .. inst)
    tprint(val)
end


-- users database operations
function d_users(inst, operation, val)
    ngx.say("d_users " .. operation .. " for " .. inst)
    tprint(val)
end


-- funder_ds_map database operations
function d_funder_ds_map(inst, operation, val)
    ngx.say("d_funder_ds_map " .. operation .. " for " .. inst)
    tprint(val)
end


-- main
local inst = ngx.var.inst_id
local object = ngx.var.object
local operation = ngx.var.operation
local object_function_map = {
    institution = d_institution,
    faculty = d_faculty,
    funder = d_funder,
    funder_dmp_states = d_funder_dmp_states,
    department = d_department,
    storage_costs = d_storage_costs,
    dataset = d_dataset,
    dataset_accesses = d_dataset_accesses,
    publication = d_publication,
    project = d_project,
    users = d_users,
    funder_ds_map = d_funder_ds_map,
    funder_pub_map = d_funder_pub_map,
    pub_ds_map = d_pub_ds_map,
    dept_ds_map = d_dept_ds_map,
    dept_pub_map = d_dept_pub_map,
    project_pub_map = d_project_pub_map,
    project_ds_map = d_project_ds_map,
    funder_project_map = d_funder_project_map,
    inst_ds_map = d_inst_ds_map
}

if object_function_map[object] then
    object_function_map[object](inst, operation, form_to_table())
else
    ngx.say("No function found in object_function_map for "
            .. operation .. " on " .. object)
end
