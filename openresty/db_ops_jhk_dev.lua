
local cjson = require 'cjson'
local upload = require 'resty.upload'
local http = require 'socket.http'

local debug_flag = ''
local print_sql
local util

local base_uri

-- put json data from form into lua table
local function form_to_table()
    local form, err = upload:new(1048576)
    if not form then
        util.log_error('failed to create form using upload:new -  ' ..  err)
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

-- gets the query templates
local function read_templates(qtf)
    dofile(qtf)
    return query_templates
end

--[[
Actually submits the query, returning the json encoded result and an
approriate return code.
--]]
local function do_db_operation(d, query, method)
    local return_code
    if print_sql then
        -- return the query text rather than the query results
        return ngx.HTTP_OK, '{"query": ' .. cjson.encode(query) .. '}'
    else
        local res, err = d:query(query)
        if not res then
            return ngx.HTTP_BAD_REQUEST, util.error_to_json(err .. ' query = '
                .. query)
        end
        if method == 'POST' then
            return_code = ngx.HTTP_CREATED
            return return_code, cjson.encode(res)
        elseif method == 'DELETE' then
            return_code = 204
            return return_code, cjson.encode(res)
        else
            return_code = ngx.HTTP_OK
            if res[1] == nil then
                -- an attempt to be consistent, postgres return an empty '{}'
                -- object and we would prefer to return an empty '[]' array
                return return_code, '[]'
            else
                return return_code, cjson.encode(res)
            end
        end
    end
end


--[[
construct a list of columns to be operated on, the values to use and
optionally the primary key and it's value (for updates) and return all of those
things. Note the use of a common lua idiom. String concatenation using .. is
an expensive operation and to be avioded in a loop. So a data table is built
and when complete converted to a string using table.concat().
--]]
local function columns_rows_maker(d, t_data)
    -- d is the database connection
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


--[[
takes a variable number of parameter strings, puts them in a table and
uses table.concat to make a string. It's much faster than
string concatenation, especially when used in a loop
--]]
local function fast_concat(...)
    local t = {}
    for _, v in ipairs({...}) do
        t[#t + 1] = v
    end
    return table.concat(t)
end


-- populates the variable clauses for the query by iterating
-- through the provided arguments
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
                            var == 'summary_by_date' or
                            var == 'summary_totals'
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
                    if (q == 'datasets') or (q == 'dmp_status') then
                        if args['filter'] == 'rcuk' then
                            clause = string.gsub(clause,
                                '#project_null_dates#', '')
                        else
                            clause = string.gsub(clause,
                                '#project_null_dates#',
                                'or project_date_range is null')
                        end
                    end
                elseif (var == 'has_dmp') or (var == 'is_awarded') then
                    if value == 'true' then
                        clause = string.gsub(clause, '#not#', '')
                    else
                        clause = string.gsub(clause, '#not#', 'not')
                    end
                elseif (var == 'modifiable' or var == 'ispi_list') then
                    clause = ''
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

-- tidy up the query string, removing extra space and end of lines
local function clean_query(q)
    q = string.gsub(q, '\n', '')
    q = string.gsub(q, '  *', ' ')
    q = util.trim(q)
    return q
end


local function dataset_accesses_special(query, q, qt, args, db)
    if args['summary_totals'] == 'true' then
        q = string.gsub(q, '#summary_column#',
            qt[query]['summary_column_4'])
        q = string.gsub(q, '#summary_clause#',
            qt[query]['summary_clause_2'])
        q = string.gsub(q, '#group_by_clause#',
            qt[query]['group_by_clause_4'])
        q = string.gsub(q, '#order_clause#',
            qt[query]['output_order_4'])
    elseif args['summary'] == 'true' then
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
    return(q)
end


local function construct_c_query(db, inst, query, method, qtf)
    local institution = db:escape_literal(inst)
    local qt = read_templates(qtf)
    local args = ngx.req.get_uri_args()
    local q
    -- todo: delete and put procesing could be combined
    if method == 'DELETE' then
        q = qt[query]['delete']
        local pkeys = qt[query]['delete_pkeys']
        for _, k in pairs(pkeys) do
            if not args[k] then
                util.log_error(query .. ' delete requires a ' ..
                    k .. ' parameter')
                ngx.exit(ngx.HTTP_BAD_REQUEST)
            else
                q = string.gsub(q, '#' .. k .. '#',
                    db:escape_literal(args[k]))
            end
        end
        q = string.gsub(q, '#inst_id#', institution)
    elseif method == 'PUT' then
        q = qt[query]['put']
        local pkeys= qt[query]['put_pkeys']
        for _, k in pairs(pkeys) do
            if not args[k] then
                util.log_error(query .. ' put requires a ' ..
                    k .. ' parameter.')
                ngx.exit(ngx.HTTP_BAD_REQUEST)
            else
                q = string.gsub(q, '#' .. k .. '#',
                    db:escape_literal(args[k]))
            end
        end
        local u_count = 0
        q = string.gsub(q, '#inst_id#', institution)
        local updateable_columns = qt[query]['put_updateable_columns']
        for _, c in pairs(updateable_columns) do
            if args[c] then
                local c_name = c
                if u_count > 0 then
                    c_name = ', ' .. c_name
                end
                q = string.gsub(q, '#set_' .. c .. '#', c_name .. ' = ' ..
                    db:escape_literal(args[c]))
                u_count = u_count + 1
            else
                q = string.gsub(q, '#set_' .. c .. '#', '')
            end
        end
    else
        if args['modifiable'] then
            query = query .. '_modifiable'
            q = qt[query]['query']
        elseif args['ispi_list'] then
            query = query .. '_ispi_list'
            q = qt[query]['query']
        else
            q = qt[query]['query']
        end
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
            q = dataset_accesses_special(query, q, qt, args, db)
        end
        q = string.gsub(q, '#inst_id#', institution)
    end
    return clean_query(q)
end


-- utility 'u' queries
local function construct_u_query(db, inst, query, method, qtf)
    local institution = db:escape_literal(inst)
    local qt = read_templates(qtf)
    local q = qt[query]['query']
    q = string.gsub(q, '#inst_id#', institution)
    return clean_query(q)
end


-- open 'o' queries, no api_key required
local function construct_o_query(db, inst, query, method, qtf)
    local qt = read_templates(qtf)
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
local function do_cuo_query(db, qtype, qtf)
    local inst = util.get_inst()
    local query = ngx.var.query
    local method = ngx.req.get_method()
    if (qtype ~= construct_c_query) and (method ~= 'GET') then
        local e = method .. ' not supported for query on '
            .. query .. ' in ' .. inst
        util.log_error(e)
        return ngx.HTTP_METHOD_NOT_IMPLEMENTED, util.error_to_json(e)
    else
        return do_db_operation(
            db, qtype(db, inst, query, method, qtf), method
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
    util.log_debug('api_key for ' .. inst ..' = ' .. stored_api_key)
    if api_key ~= stored_api_key then
        util.log_error('HTTP_FORBIDDEN to '
            .. ngx.var.remote_addr .. ' with api_key = ' .. api_key)
        ngx.exit(ngx.HTTP_FORBIDDEN)
    end
end


local function db_operation(db, query_template_file)
    local c_query = ngx.var.c_query
    local u_query = ngx.var.u_query
    local o_query = ngx.var.o_query
    if o_query == 'true' then
        return do_cuo_query(db, construct_o_query, query_template_file)
    elseif c_query == 'true' then
        check_api_key(db, ngx.var.inst_id, ngx.var.api_key)
        return do_cuo_query(db, construct_c_query, query_template_file)
    elseif u_query == 'true' then
        --check_api_key(db, ngx.var.inst_id, ngx.var.api_key)
        return do_cuo_query(db, construct_u_query, query_template_file)
    else -- direct operations on database tables
        check_api_key(db, ngx.var.inst_id, ngx.var.api_key)
        local inst = util.get_inst()
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
            query = fast_concat(
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
                util.log_error(e)
                return ngx.HTTP_BAD_REQUEST, util.error_to_json(e)
            end
            query = fast_concat(
                'update ', object,
                ' set ', columns, ' = ', values,
                ' where inst_id = ', db:escape_literal(inst),
                ' and ',
                pkey, ' = ', pkey_val,
                ' returning *;'
            )
        elseif method == 'DELETE' then
            if k and v then
                query = fast_concat(
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
                util.log_error(e)
                return ngx.BAD_REQUEST, util.error_to_json(e)
            end
        elseif method == 'GET' then
            if k and v then
                query = fast_concat(
                    'select * from ', object,
                    ' where inst_id = ', db:escape_literal(inst),
                    ' and ',
                    k, ' = ', db:escape_literal(v),
                    ';'
                )
            else
                query = fast_concat(
                    'select * from ', object,
                    ' where inst_id = ', db:escape_literal(inst),
                    ';'
                )
            end
        else
            local e = 'No defined action for http_method = ' .. method
            util.log_error(e)
            return ngx.HTTP_METHOD_NOT_IMPLEMENTED, util.error_to_json(e)
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
    util.log_error('No environment available')
    ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

local base_path
local conn_file
local q_template_file

if environment == 'jhk_dev' then
    local host = 'localhost'
    debug_flag = true
    print_sql = false
    base_uri = 'http://' .. host .. ':' .. port .. '/dmaonline/v0.3'
    base_path = '/Users/krug/projects/dmao_infrastructure'
    package.path = package.path .. ';' .. base_path
        .. '/openresty/?.lua;/usr/local/lib/luarocks/rocks-5.1/?.lua'
    conn_file = base_path .. '/openresty/connection_jhk_dev.lua'
    q_template_file = base_path .. '/openresty/query_templates_jhk_dev.lua'
    util = require 'dmao_i_utility_jhk_dev'
elseif environment == 'dev' then
    local host = 'localhost'
    debug_flag = true
    print_sql = false
    base_uri = 'http://' .. host .. ':' .. port .. '/dmaonline/v0.3'
    base_path = '/home/dmao_infrastructure/deploy'
    package.path = package.path .. ';' .. base_path
        .. '/openresty/?.lua;/usr/local/lib/luarocks/rocks/?.lua'
    conn_file = base_path .. '/openresty/connection_dev.lua'
    q_template_file = base_path .. '/openresty/query_templates_dev.lua'
    util = require 'dmao_i_utility_dev'
elseif environment == 'test' then
    local host = 'localhost'
    debug_flag = true
    print_sql = false
    base_uri = 'http://' .. host .. ':' .. port .. '/dmaonline/v0.3'
    base_path = '/home/dmao_infrastructure/deploy'
    package.path = package.path .. ';' .. base_path
        .. '/openresty/?.lua;/usr/local/lib/luarocks/rocks/?.lua'
    conn_file = base_path .. '/openresty/connection_test.lua'
    q_template_file = base_path .. '/openresty/query_templates_test.lua'
    util = require 'dmao_i_utility_test'
elseif environment == 'live' then
    local host = 'localhost'
    debug_flag = false
    print_sql = false
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

local db = util.open_dmaonline_db(conn_file)
local status, result = db_operation(db, q_template_file)
util.close_dmaonline_db(db)
ngx.header.content_type = 'application/json';
ngx.status = status
ngx.say(result)
