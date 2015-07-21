
cjson = require 'cjson'
upload = require 'resty.upload'
pg = require 'pgmoon'

-- TODO: Needs some work to make this generic

function tprint (tbl, indent)
    if not indent then indent = 4 end
    for k, v in pairs(tbl) do
        local formatting = string.rep('  ', indent) .. k .. ': '
        if type(v) == 'table' then
            ngx.say(formatting)
            tprint(v, indent+1)
        elseif type(v) == 'boolean' then
            ngx.say(formatting .. tostring(v))
        else
            ngx.say(formatting .. v)
        end
    end
end

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

function get_connection_details()
    local f = "/usr/local/openresty/lualib/connection.conf"
    dofile(f)
    return user, passwd
end

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

function close_dmaonline_db(c)
    assert(c:disconnect())
end

function insert_institution_values(values)
    local d = open_dmaonline_db()
    local v = d:escape_literal(values['inst_id']) .. ', '
    v = v .. d:escape_literal(values['name']) .. ', '
    v = v .. d:escape_literal(values['contact']) .. ', '
    v = v .. d:escape_literal(values['contact_phone']) .. ', '
    v = v .. d:escape_literal(values['contact_email']) .. ', '
    v = v .. d:escape_literal(values['cris_sys']) .. ', '
    v = v .. d:escape_literal(values['pub_sys']) .. ', '
    v = v .. d:escape_literal(values['dataset_sys']) .. ', '
    v = v .. d:escape_literal(values['archive_sys']) .. ', '
    v = v .. d:escape_literal(values['currency']) .. ', '
    v = v .. d:escape_literal(values['currency_symbol'])
    local q = "insert into institution values (" .. v .. ") returning *;"
    local res = assert(d:query(q))
    ngx.say(cjson.encode(res[1]))
    close_dmaonline_db(d)
end

function insert_department_values(inst, values)
    ngx.say('insert_department_values for ' .. inst)
    tprint(values)
end

function insert_faculty_values(inst, values)
    ngx.say('insert_faculty_values for ' .. inst)
    tprint(values)
end

local inst = ngx.var.inst_id
local object = ngx.var.object
local object_function_table = {
    department = insert_department_values,
    faculty = insert_faculty_values
}

if object == "institution" then -- a special case
    insert_institution_values(form_to_table())
elseif object_function_table[object] then
    object_function_table[object](inst, form_to_table())
else
    ngx.say("No function found for operation on " .. object)
end
