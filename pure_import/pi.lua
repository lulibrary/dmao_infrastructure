-- pure data import tools
package.path = package.path .. ';../openresty/?.lua;'
util = require 'dmao_i_utility'
xml = require 'xml'
lub = require 'lub'

local f = assert(io.open('data/pure_orgs.xml'))

local x = xml.load(f:read'*a')

local list = {}
lub.search(
    x,
    function(node)
        if node.xml == 'a:OrganisationList' then
            local id = xml.find(node, 'a:OrganisationID')
            local name = xml.find(node, 'a:OrganisationName')
            local type = xml.find(node, 'a:Type')
            table.insert(list, id[1] .. '###' .. type[1] .. '###' .. name[1])
        end
    end
)

--print(xml.dump(list))
--util.tprint(list, print)
for _, v in pairs(list) do
    print(v)
end
f:close()