cjson = require 'cjson'
upload = require 'resty.upload'

function tprint (tbl, indent)
    if not indent then indent = 4 end
    for k, v in pairs(tbl) do
        formatting = string.rep('  ', indent) .. k .. ': '
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
    form:set_timeout(2000) -- 2 seconds
    while true do
        local typ, res, err = form:read()
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

local t = form_to_table()
local u = ngx.var['base_url'] ..
    '/institution?' ..
    '&inst_id=' .. t['inst_id'] ..
    '&name=' .. ngx.escape_uri(t['name']) ..
    '&contact=' .. ngx.escape_uri(t['contact']) ..
    '&phone=' .. ngx.escape_uri(t['contact_phone']) ..
    '&email=' .. ngx.escape_uri(t['contact_email']) ..
    '&cris_sys=' .. ngx.escape_uri(t['cris_sys']) ..
    '&pub_sys=' .. ngx.escape_uri(t['pub_sys']) ..
    '&dataset_sys=' .. ngx.escape_uri(t['dataset_sys']) ..
    '&archive_sys=' .. ngx.escape_uri(t['archive_sys'])
res = ngx.location.capture(u, {method=ngx.HTTP_POST})
ngx.say(res.body)
