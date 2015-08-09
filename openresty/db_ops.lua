
cjson = require 'cjson'
upload = require 'resty.upload'
pg = require 'pgmoon'

debug = false
debug = true
environment = "dev" -- or test or prod
base_uri = ''

if environment == "dev" then
    local host = "localhost"
    local port = "8080"
    base_uri = "http://" .. host .. ":" .. port .. "/dmaonline/lua_test"
end


-- iterate through a lua table to print via nginx, for debugging purposes.
local function tprint(tbl, indent)
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


--[[
Apologies, this is here to swallow Pycharm warnings about 'unused
assigment' in the cases where I'm convinced that the code inspector has
got it wrong. It enables me to see a green tick, which, sadly, I like to
see before I deploy. Hopefully, it's mostly optimised away. It's an
open case for the lua plugin, maybe it will get fixed.
--]]
local function swallow(v)
    if v then end
end


-- put json data from form into lua table
local function form_to_table()
    local form, err = upload:new(8192)
    if not form then
        ngx.log(ngx.ERR, 'failed to upload:new -  ', err)
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end
    form:set_timeout(2000) -- 2 seconds
    while true do
        local typ, res, err = form:read()
        if not typ then
            ngx.say('failed to form:read - ', err)
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



local function get_connection_details()
    local f = '/usr/local/openresty/lualib/connection.conf'
    dofile(f)
    return user, passwd
end


local function open_dmaonline_db()
    local u, p = get_connection_details()
    local d = pg.new(
        {
            host='127.0.0.1',
            port='5432',
            database='DMAonline',
            user=u, password=p
        }
    )
    assert(d:connect())
    return d
end


local function close_dmaonline_db(c)
    assert(c:disconnect())
end


local function error_to_json(e)
    return '[{"error": ' .. cjson.encode(e) .. '}]'
end


local function do_db_operation(d, query, method)
    local return_code
    if debug then
        swallow(d)
        return ngx.HTTP_OK, '[{"query": ' .. cjson.encode(query) .. '}]'
    else
        local res, err = d:query(query)
        if not res then
            return ngx.HTTP_BAD_REQUEST,
                '[{"error": ' .. cjson.encode(err) .. '}]'
        end
        if method == 'POST' then
            return_code = ngx.HTTP_CREATED
            swallow(return_code)
        else
            return_code = ngx.HTTP_OK
            swallow(return_code)
        end
        return return_code, cjson.encode(res)
    end
end


--[[
construct a list of columns to be operated on, the values to use and
optionally the primary key and it's value (for updates)
--]]
local function columns_rows_maker(d, t_data)
    local pkey
    local pkey_val
    local a = {'(' }
    local b = {}
    for i, row in pairs(t_data) do
        b[#b + 1] = '('
        for column, value in pairs(row) do
            if i == 1 then
                if string.match(column, '^pkey:') then
                    column = string.gsub(column, '^pkey:', '')
                    pkey = column
                    pkey_val = d:escape_literal(value)
                end
                a[#a + 1] = column
                a[#a + 1] = ', '
            end
            b[#b + 1] = d:escape_literal(value)
            b[#b + 1] = ', '
        end
        b[#b + 1] = '), '
    end
    local col_list = table.concat(a)
    col_list = string.gsub(col_list, ', $', ')')
    local val_list = table.concat(b)
    val_list = string.gsub(val_list, ', %)', ')')
    val_list = string.gsub(val_list, ', $', '')
    return col_list, val_list, pkey, pkey_val
end


local function make_sql(...)
    local t = {}
    for _, v in ipairs({...}) do
        t[#t + 1] = v
    end
    return table.concat(t)
end


local function db_operation(db)
    local inst = ngx.var.inst_id
    local object = ngx.var.object
    local method = ngx.req.get_method()
    local k, v
    if ngx.var.pkey then
        k, v = ngx.var.pkey, ngx.var.value
    end
    local query
    if method == 'POST' then
        local data_table = form_to_table()
        local columns, values, pkey, pkey_val =
        columns_rows_maker(db, data_table)
        query = make_sql(
            'insert into ', object, columns,
            ' values ', values,
            ';'
        )
        swallow(query)
    elseif method == 'PUT' then
        local data_table = form_to_table()
        local columns, values, pkey, pkey_val =
            columns_rows_maker(db, data_table)
        if not pkey then
            local e = 'Incorrect data specification ' ..
                    'for update (no pkey specified)'
            ngx.log(ngx.ERR, e)
            return ngx.HTTP_BAD_REQUEST, error_to_json(e)
        end
        query = make_sql(
            'update ', object,
            ' set ', columns, ' = ', values,
            ' where inst_id = ', db:escape_literal(inst),
            ' and ',
            pkey, ' = ', pkey_val,
            ' returning *;'
        )
        swallow(query)
    elseif method == 'DELETE' then
        if k and v then
            query = make_sql(
                'delete from ', object,
                ' where inst_id = ', db:escape_literal(inst),
                ' and ',
                k, ' = ', db:escape_literal(v),
                ';'
            )
            swallow(query)
        else
            local e = 'No pkey and value specified for for http_method = '
                    .. method
            ngx.log(ngx.ERR, e)
            return ngx.HTTP_METHOD_NOT_IMPLEMENTED, error_to_json(e)
        end
    elseif method == 'GET' then
        if k and v then
            query = make_sql(
                'select * from ', object,
                ' where inst_id = ', db:escape_literal(inst),
                ' and ',
                k, ' = ', db:escape_literal(v),
                ';'
            )
            swallow(query)
        else
            query = make_sql(
                'select * from ', object,
                ' where inst_id = ', db:escape_literal(inst),
                ';'
            )
            swallow(query)
        end
    else
        local e = 'No defined action for http_method = ' .. method
        ngx.log(ngx.ERR, e)
        return ngx.HTTP_METHOD_NOT_IMPLEMENTED, error_to_json(e)
    end
    local status, result = do_db_operation(db, query, method)
    if method == "POST" then
        ngx.header["Location"] = base_uri ..  "/" .. inst .. "/" .. object
    end
    return status, result
end


-- main
local db = open_dmaonline_db()
local status, result = db_operation(db)
close_dmaonline_db(db)
ngx.status = status
ngx.say(result)
