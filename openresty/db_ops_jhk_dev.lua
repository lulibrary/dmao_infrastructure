
-- determine environment based on port number the request is received at

local port = ngx.var.port
local environment
if port == '8070' then
    environment = 'jhk_dev'
elseif port == '8090' then
    environment = 'dev'
elseif port == '8080' then
    environment = 'test'
elseif port == '80' then
    environment = 'live'
else
    ngx.log(ngx.ERR, 'No environment available')
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

local debug
local base_uri
local base_path
local conn_file
local q_template_file
local util

if environment == 'jhk_dev' then
    local host = 'localhost'
    debug = false
    base_uri = 'http://' .. host .. ':' .. port .. '/dmaonline/v0.3'
    base_path = '/Users/krug/projects/dmao_infrastructure'
    package.path = package.path .. ';' .. base_path
        .. '/openresty/?.lua;/usr/local/lib/luarocks/rocks-5.1/?.lua'
    conn_file = base_path .. '/openresty/connection_jhk_dev.lua'
    q_template_file = base_path .. '/openresty/query_templates_jhk_dev.lua'
    util = require 'dmao_i_utility_jhk_dev'
elseif environment == 'dev' then
    local host = 'localhost'
    debug = false
    base_uri = 'http://' .. host .. ':' .. port .. '/dmaonline/v0.3'
    base_path = '/home/dmao_infrastructure/deploy'
    package.path = package.path .. ';' .. base_path
        .. '/openresty/?.lua;/usr/local/lib/luarocks/rocks/?.lua'
    conn_file = base_path .. '/openresty/connection_dev.lua'
    q_template_file = base_path .. '/openresty/query_templates_dev.lua'
    util = require 'dmao_i_utility_dev'
elseif environment == 'test' then
    local host = 'localhost'
    debug = false
    base_uri = 'http://' .. host .. ':' .. port .. '/dmaonline/v0.3'
    base_path = '/home/dmao_infrastructure/deploy'
    package.path = package.path .. ';' .. base_path
        .. '/openresty/?.lua;/usr/local/lib/luarocks/rocks/?.lua'
    conn_file = base_path .. '/openresty/connection_test.lua'
    q_template_file = base_path .. '/openresty/query_templates_test.lua'
    util = require 'dmao_i_utility_test'
elseif environment == 'live' then
    local host = 'localhost'
    debug = false
    base_uri = 'http://' .. host .. ':' .. port .. '/dmaonline/v0.3'
    base_path = '/home/dmao_infrastructure/deploy'
    package.path = package.path .. ';' .. base_path
        .. '/openresty/?.lua;/usr/local/lib/luarocks/rocks/?.lua'
    conn_file = base_path .. '/openresty/connection_live.lua'
    q_template_file = base_path .. '/openresty/query_templates_live.lua'
    util = require 'dmao_i_utility_live'
else
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

local cjson = require 'cjson'
local upload = require 'resty.upload'
local http = require 'socket.http'

-- put json data from form into lua table
local function form_to_table()
    local form, err = upload:new(1048576)
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


local function read_templates()
    dofile(q_template_file)
    return query_templates
end


local function error_to_json(e)
    return '[{"error": ' .. cjson.encode(e) .. '}]'
end


local function do_db_operation(d, query, method)
    local return_code
    if debug then
        return ngx.HTTP_OK, '[{"query": ' .. cjson.encode(query) .. '}]'
    else
        local res, err = d:query(query)
        if not res then
            return ngx.HTTP_BAD_REQUEST,
                '[{"error": ' .. cjson.encode(err) .. '}]'
        end
        if method == 'POST' then
            return_code = ngx.HTTP_CREATED
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
            if value == 'null_value' then
                b[#b + 1] = 'null'
            else
                b[#b + 1] = d:escape_literal(value)
            end
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


local function populate_var_clauses(q, db, args, template)
    local clauses = {}
    if args then
        for var, value in pairs(args) do
            if not (
                (var == 'sd') or (var == 'ed')
                    or (var == 'filter') or (var == 'count')
                    or (
                        q == 'dataset_accesses'
                        and
                        (
                            var == 'dataset_id' or
                            var == 'summary' or
                            var == 'summary_by_date'
                        )
                    )
            ) then
                local clause = template[var]
                if var == 'date' then
                    clause = string.gsub(clause, '#var_value#', value)
                    clause = string.gsub(clause, '#el_sd#',
                        db:escape_literal(args['sd']))
                    clause = string.gsub(clause, '#el_ed#',
                        db:escape_literal(args['ed']))
                    if q == 'datasets' then
                        if args['filter'] == 'rcuk' then
                            clause = string.gsub(clause,
                                '#project_null_dates#', '')
                        else
                            clause = string.gsub(clause,
                                '#project_null_dates#',
                                'or p.project_date_range is null')
                        end
                    end
                elseif (var == 'has_dmp') or (var == 'is_awarded') then
                    if value == 'true' then
                        clause = string.gsub(clause, '#not#', '')
                    else
                        clause = string.gsub(clause, '#not#', 'not')
                    end
                else
                    clause = string.gsub(clause, '#el_var_value#',
                        db:escape_literal(value))
                end
                clauses[#clauses + 1] = clause
                clauses[#clauses + 1] = ' '
            end
        end
    end
    return table.concat(clauses)
end


local function clean_query(q)
    q = string.gsub(q, '\n', '')
    q = string.gsub(q, '  *', ' ')
    q = string.gsub(q, '^ ', '')
    q = string.gsub(q, ' $', ';')
    return q
end


local function construct_c_query(db, inst, query, method)
    local institution = db:escape_literal(inst)
    local qt = read_templates()
    local args = ngx.req.get_uri_args()
    local q
    if method == 'PUT' then
        q = qt[query]['query']
        if query == 'project_dmps_view_put' then
            if not args['project_id'] then
                ngx.exit(ngx.HTTP_BAD_REQUEST)
            else
                q = string.gsub(q, '#project_id#',
                    db:escape_literal(args['project_id']))
            end
        end
        local u_count = 0
        q = string.gsub(q, '#inst_id#', institution)
        if args['dmp_id'] then
            q = string.gsub(q, '#dmp_id#', 'dmp_id = ' ..
                db:escape_literal(args['dmp_id']))
            u_count = u_count + 1
        else
            q = string.gsub(q, '#dmp_id#', '')
        end
        if args['has_dmp'] then
            local c_name = 'has_dmp'
            if u_count > 0 then
                c_name = ', ' .. c_name
            end
            q = string.gsub(q, '#has_dmp#', c_name .. ' = ' ..
                db:escape_literal(args['has_dmp']))
            u_count = u_count + 1
        else
            q = string.gsub(q, '#has_dmp#', '')
        end
        if args['has_dmp_been_reviewed'] then
            local c_name = 'has_dmp_been_reviewed'
            if u_count > 0 then
                c_name = ', ' .. c_name
            end
            q = string.gsub(q, '#has_dmp_been_reviewed#', c_name .. ' = ' ..
                db:escape_literal(args['has_dmp_been_reviewed']))
            u_count = u_count + 1
        else
            q = string.gsub(q, '#has_dmp_been_reviewed#', '')
        end
    else
        q = qt[query]['query']
        local vc = populate_var_clauses(
            query, db, args, qt[query]['variable_clauses']
        )
        if args['count'] then
            q = string.gsub(q, '#columns_list#',
                qt[query]['columns_list_count'])
            q = string.gsub(q, '#order_clause#', '')
            q = string.gsub(q, '#group_by_clause#', '')
        else
            q = string.gsub(q, '#columns_list#', qt[query]['columns_list'])
            if (query ~= 'dataset_accesses') then
                q = string.gsub(q, '#order_clause#', qt[query]['output_order'])
                q = string.gsub(q, '#group_by_clause#', qt[query]['group_by'])
            end
        end
        if args['filter'] then
            q = string.gsub(q, '#funder_id_filter_clause#',
                qt[query]['variable_clauses']['filter'])
        else
            q = string.gsub(q, '#funder_id_filter_clause#', '')
        end
        q = string.gsub(q, '#variable_clauses#', vc)
        -- unfortunately, special processing, todo: improve this
        if query == 'dataset_accesses' then
            if args['summary'] == 'true' then
                q = string.gsub(q, '#summary_column#',
                    qt[query]['summary_column_1'])
                q = string.gsub(q, '#summary_clause#',
                    qt[query]['summary_clause_2'])
                q = string.gsub(q, '#group_by_clause#',
                    qt[query]['group_by_clause_2'])
                q = string.gsub(q, '#order_clause#',
                    qt[query]['output_order_2'])
            elseif args['summary_by_date'] == 'true' then
                q = string.gsub(q, '#summary_column#',
                    qt[query]['summary_column_2'])
                q = string.gsub(q, '#summary_clause#',
                    qt[query]['summary_clause_2'])
                q = string.gsub(q, '#group_by_clause#',
                    qt[query]['group_by_clause_3'])
                q = string.gsub(q, '#order_clause#',
                    qt[query]['output_order_3'])
            else
                q = string.gsub(q, '#summary_column#',
                    qt[query]['summary_column_1'])
                q = string.gsub(q, '#summary_clause#',
                    qt[query]['summary_clause_1'])
                q = string.gsub(q, '#group_by_clause#',
                    qt[query]['group_by_clause_1'])
                q = string.gsub(q, '#order_clause#',
                    qt[query]['output_order_1'])
            end
            if not args['dataset_id'] and not args['sd'] then
                q = string.gsub(q, '#and_clause_1#', '')
                q = string.gsub(q, '#and_clause_2#', '')
            end
            if args['dataset_id'] then
                q = string.gsub(q, '#and_clause_1#', 'and')
                q = string.gsub(q, '#dataset_id#',
                    string.gsub(qt[query]['dataset_id'], '#el_var_value#',
                        db:escape_literal(args['dataset_id'])))
            else
                q = string.gsub(q, '#dataset_id#', '')
            end
            if args['sd'] then
                q = string.gsub(q, '#and_clause_1#', 'and')
                local date_range =
                    string.gsub(qt[query]['sd'], '#el_var_value#',
                        db:escape_literal(args['sd']))
                    .. ' ' ..
                    string.gsub(qt[query]['ed'], '#el_var_value#',
                        db:escape_literal(args['ed']))
                q = string.gsub(q, '#date_range#', date_range)
            else
                q = string.gsub(q, '#date_range#', '')
            end
            if args['dataset_id'] and args['sd'] then
                q = string.gsub(q, '#and_clause_2#', 'and')
            else
                q = string.gsub(q, '#and_clause_2#', '')
            end
        end
        q = string.gsub(q, '#inst_id#', institution)
    end
    return clean_query(q)
end


local function construct_u_query(db, inst, query)
    local institution = db:escape_literal(inst)
    local qt = read_templates()
    local q = qt[query]['query']
    q = string.gsub(q, '#inst_id#', institution)
    return clean_query(q)
end


local function construct_o_query(db, inst, query)
    local qt = read_templates()
    local q
    if query == 'o_get_api_key' then
        q = qt[query]['query']
        local args = ngx.req.get_uri_args()
        local user = db:escape_literal(args['user'])
        local passwd = db:escape_literal(args['passwd'])
        local institution = db:escape_literal(inst)
        q = string.gsub(q, '#inst_id#', institution)
        q = string.gsub(q, '#username#', user)
        q = string.gsub(q, '#passwd#', passwd)
    else
        q = qt[query]['query']
    end
    return clean_query(q)
end


-- pre-defined 'canned', 'utility' and 'open' queries
local function do_cuo_query(db, qtype)
    local inst = ngx.var.inst_id
    local query = ngx.var.query
    local method = ngx.req.get_method()
    if (qtype ~= construct_c_query) and (method ~= 'GET') then
        local e = method .. ' not supported for query on '
            .. query .. ' in ' .. inst
        ngx.log(ngx.ERR, e)
        return ngx.HTTP_METHOD_NOT_IMPLEMENTED, error_to_json(e)
    else
        return do_db_operation(
            db, qtype(db, inst, query, method), method
        )
    end
end


local function check_api_key(db, inst, api_key)
    local q = [[
        select
            coalesce(max(api_key), 'not_found') as api_key
        from
            institution
        where
            inst_id =
        ]] .. db:escape_literal(inst) .. ';'
    local res = db:query(q)
    local stored_api_key = res[1]['api_key']
    ngx.log(ngx.INFO, 'api_key = ' .. stored_api_key)
    if api_key ~= stored_api_key then
        ngx.log(ngx.ERR, 'HTTP_FORBIDDEN to '
            .. ngx.var.remote_addr .. ' with api_key = ' .. api_key)
        ngx.exit(ngx.HTTP_FORBIDDEN)
    end
end


local function db_operation(db)
    local c_query = ngx.var.c_query
    local u_query = ngx.var.u_query
    local o_query = ngx.var.o_query
    if c_query == 'true' then
        check_api_key(db, ngx.var.inst_id, ngx.var.api_key)
        return do_cuo_query(db, construct_c_query)
    elseif o_query == 'true' then
        return do_cuo_query(db, construct_o_query)
    elseif u_query == 'true' then
        check_api_key(db, ngx.var.inst_id, ngx.var.api_key)
        return do_cuo_query(db, construct_u_query)
    else
        check_api_key(db, ngx.var.inst_id, ngx.var.api_key)
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
        elseif method == 'DELETE' then
            if k and v then
                query = make_sql(
                    'delete from ', object,
                    ' where inst_id = ', db:escape_literal(inst),
                    ' and ',
                    k, ' = ', db:escape_literal(v),
                    ';'
                )
            else
                local e = 'No pkey and value specified ' ..
                        'for for http_method = '
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
            else
                query = make_sql(
                    'select * from ', object,
                    ' where inst_id = ', db:escape_literal(inst),
                    ';'
                )
            end
        else
            local e = 'No defined action for http_method = ' .. method
            ngx.log(ngx.ERR, e)
            return ngx.HTTP_METHOD_NOT_IMPLEMENTED, error_to_json(e)
        end
        local status, result = do_db_operation(db, query, method)
        if method == "POST" then
            ngx.header["Location"] = base_uri ..  "/" .. inst
                    .. "/" .. object
        end
        return status, result
    end
end


-- main
local db = util.open_dmaonline_db(conn_file)
local status, result = db_operation(db)
util.close_dmaonline_db(db)
ngx.header.content_type = 'application/json';
ngx.status = status
ngx.say(result)