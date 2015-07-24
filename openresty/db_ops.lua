
cjson = require 'cjson'
upload = require 'resty.upload'
pg = require 'pgmoon'

debug = false
debug = true


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

function do_db_operation(d, q)
    if debug then
        ngx.say(q)
    else
        local res = assert(d:query(q))
        ngx.say(cjson.encode(res))
        -- TODO: Make sure correct HTTP headers are being returned
    end
end


function columns_rows_maker(d, t_data)
    local a = {"(" }
    local b = {}
    for i, row in pairs(t_data) do
        b[#b + 1] = "("
        for column, value in pairs(row) do
            if i == 1 then
                a[#a + 1] = column
                a[#a + 1] = ", "
            end
            b[#b + 1] = d:escape_literal(value)
            b[#b + 1] = ", "
        end
        b[#b + 1] = "), "
    end
    local col_list = table.concat(a)
    col_list = string.gsub(col_list, ", $", ")")
    local val_list = table.concat(b)
    val_list = string.gsub(val_list, ", %)", ")")
    val_list = string.gsub(val_list, ", $", "")
    return col_list, val_list
end


function db_operation(object, operation, inst, data_table)
    local db = open_dmaonline_db()
    local t_query = {}
    local columns, values = columns_rows_maker(db, data_table)
    if operation == "insert" then
        t_query[#t_query + 1] = "insert into "
        t_query[#t_query + 1] = object
        t_query[#t_query + 1] = columns
        t_query[#t_query + 1] = " values "
        t_query[#t_query + 1] = values
        t_query[#t_query + 1] = " returning *;"
    elseif operation == "update" then
        ngx.say("update on " .. object)
    elseif operation == "delete" then
        t_query[#t_query + 1] = "delete from "
        t_query[#t_query + 1] = object
        t_query[#t_query + 1] = " where inst_id = "
        t_query[#t_query + 1] = db:escape_literal(inst)
        t_query[#t_query + 1] = " and "
        t_query[#t_query + 1] = string.gsub(columns, "[%(%)]", "")
        t_query[#t_query + 1] = " = "
        t_query[#t_query + 1] = string.gsub(values, "[%(%)]", "")
        t_query[#t_query + 1] = " returning *;"
    else
        ngx.say("unknown operation - " .. operation)
    end
    local query = table.concat(t_query)
    do_db_operation(db, query)
    close_dmaonline_db(db)
end


-- main
local inst = ngx.var.inst_id
local object = ngx.var.object
local operation = ngx.var.operation

local data = form_to_table()
db_operation(object, operation, inst, data)

