local dbLib = require("inmation.database")

local db = dbLib.db
db:set("Source", "Name", "user", "password")

return function ()
    local queryString = string.format("select * from table")

    local databaseRowCount = 0
    local rowHandler = function(row)
        databaseRowCount = databaseRowCount + 1

        -- Process every column as item
        for columnName, columnValue in pairs(row) do

        end

        -- If you know the column names you can directly access it by:
        -- local column1Value = row.column1
    end

    db:open()
    -- This function can be used with a closure function.
    db:execute(queryString, rowHandler)
    db:close()
end