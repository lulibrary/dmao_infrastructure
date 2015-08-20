
cjson = require 'cjson'
upload = require 'resty.upload'
pg = require 'pgmoon'

debug = false
debug = true
environment = 'dev' -- or test or prod
base_uri = ''

if environment == 'dev' then
    local host = 'localhost'
    local port = '8080'
    base_uri = 'http://' .. host .. ':' .. port .. '/dmaonline/v0.3'
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
        swallow(method)
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


local function fill_query_template(qt, t)
    local q = qt
    for c, v in pairs(t) do
        q = string.gsub(q, '#' .. c .. '#', v)
    end
    q = string.gsub(q, '\n', '')
    q = string.gsub(q, '  *', ' ')
    return q
end


local function do_c_datasets_query(db, inst)
    local query
    local args = ngx.req.get_uri_args()
    local query_template = [[
        select
            #columns_list#
        from
            dataset d
        left outer join
            funder_ds_map fdm
        on
            (d.dataset_id = fdm.dataset_id)
        left outer join
            funder f
        on
            (fdm.funder_id = f.funder_id)
        left outer join
            faculty fac
        on
            (d.lead_faculty_id = fac.faculty_id)
        left outer join
            department dept
        on
            (d.lead_department_id = dept.department_id)
        left outer join
            project p
        on
            (d.project_id = p.project_id)
        where (
            d.dataset_id in (
                select
                    dataset_id
                from
                    funder_ds_map
                #funder_id_filter_clause#
            )
        and
            d.dataset_id in (
                select
                    dataset_id
                from
                    inst_ds_map
                where
                    inst_id = #inst_id#
            )
        )
        #arch_status_filter_clause#
        #date_filter_clause#
        #dataset_filter_clause#
        #location_filter_clause#
        #faculty_filter_clause#
        #dept_filter_clause#
        #project_filter_clause#
        #order_clause#
        ;
    ]]
    local columns_list = [[
        f.funder_id,
        f.name funder_name,
        d.*,
        fac.abbreviation lead_faculty_abbrev,
        fac.name lead_faculty_name,
        dept.abbreviation lead_dept_abbrev,
        dept.name lead_dept_name,
        p.project_awarded,
        p.project_start,
        p.project_end,
        p.project_name'
    ]]
    local project_null_dates ='or p.project_date_range is null'
    local funder_id_filter_clause = ''
    local arch_status_filter_clause = ''
    local date_filter_clause = ''
    local dataset_filter_clause = ''
    local location_filter_clause = ''
    local faculty_filter_clause = ''
    local dept_filter_clause = ''
    local project_filter_clause = ''
    local order_clause = ''
    if args['count'] == 'true' then
        columns_list = 'count(*) num_datasets'
    end
    if args['filter'] == 'rcuk' then
        funder_id_filter_clause = [[
            where funder_id in (
                select funder_id from funder where is_rcuk_funder = true
            )
        ]]
        project_null_dates = '';
    end
    if args['date'] then
        date_filter_clause = 'and (p.' .. args['date'] .. ' >= ' ..
            db:escape_literal(args['sd']) .. ' and p.' .. args['date'] ..
            ' <= ' .. db:escape_literal(args['ed']) ..
            project_null_dates .. ')'
    end
    if args['faculty'] then
        faculty_filter_clause = 'and d.lead_faculty_id = '
                .. db:escape_literal(args['faculty'])
    end
    query = fill_query_template(query_template,
        {
            columns_list = columns_list,
            funder_id_filter_clause = funder_id_filter_clause,
            inst_id = db:escape_literal(inst),
            arch_status_filter_clause = arch_status_filter_clause,
            date_filter_clause = date_filter_clause,
            dataset_filter_clause = dataset_filter_clause,
            location_filter_clause = location_filter_clause,
            faculty_filter_clause = faculty_filter_clause,
            dept_filter_clause = dept_filter_clause,
            project_filter_clause = project_filter_clause,
            order_clause = order_clause
        }
    )
    return ngx.HTTP_OK, '[{"query": ' .. cjson.encode(query) .. '}]'
end


-- pre-defined 'canned' queries
local function do_c_query(db)
    local inst = ngx.var.inst_id
    local query = ngx.var.query
    local method = ngx.req.get_method()
    -- maps queries to functions
    local qf_map = {
        datasets = do_c_datasets_query,
        project_dmps = do_c_project_dmps_query
    }
    if not (method == 'GET') then
        local e = method .. ' not supported for query on '
            .. query .. ' in ' .. inst
        ngx.log(ngx.ERR, e)
        swallow(db)
        swallow(qf_map)
        return ngx.HTTP_METHOD_NOT_IMPLEMENTED, error_to_json(e)
    else
        return qf_map[query](db, inst)
    end
end


local function db_operation(db)
    local c_query = ngx.var.c_query
    if c_query == 'true' then
        return do_c_query(db)
    else
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
                        .. method .. ' on object ' .. object
                ngx.log(ngx.ERR, e)
                return ngx.BAD_REQUEST, error_to_json(e)
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
end


-- main
local db = open_dmaonline_db()
local status, result = db_operation(db)
close_dmaonline_db(db)
ngx.status = status
ngx.say(result)
