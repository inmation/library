## inmation.condition

Import library

```lua
local conditionLib = require('inmation.condition')
```

#### conditionLib.createCondition
Creates a condition object which can be used to check whether a property value of an inmation object matches the condition.

```lua
local result = conditionLib:createCondition('ObjectName', 'StartsWith', 'Light')
-- result is 
--{
--    property = 'ObjectName', 
--    operator = 'StartsWith', 
--    value = 'Light'
--}
```

#### conditionLib.pattern
Creates a string match pattern based on the provided operator and value. The supported operators are 'Contains', 'StartsWith', 'EndsWith' and 'Equals'

```lua
local result = conditionLib:pattern('StartsWith', 'Light')
-- result is '^Light'
```

#### conditionLib.matchCondition
Matches one condition with the provided object.

```lua
local objMock = {}
objMock.ObjectName = 'Light01'
objMock.State = 1
-- Positive StartsWith match
local condition = conditionLib:createCondition('ObjectName', 'StartsWith', 'Light')
local result = conditionLib:matchCondition(condition, objMock)
-- result is 'true'
```

#### conditionLib.matchConditions
Matches one condition with the provided object.

```lua
local objMock = {}
objMock.ObjectName = 'Light01'
objMock.State = 1

local conditionList = {}
table.insert(conditionList, conditionLib:createCondition('ObjectName', 'StartsWith', 'Light'))
table.insert(conditionList, conditionLib:createCondition('ObjectName', 'StartsWith', 'Shade'))
local result = conditionLib:matchConditions(conditionList, objMock)
-- result is 'true'
```

#### conditionLib.iif
Can be used as an inline if statement

```lua
local objMock = {}
objMock.ObjectName = 'Light01'
objMock.State = 1

local result = conditionLib.iif(objMock.State == 1, 'Light01 is on.', 'Light01 is off.')''
-- result is 'Light01 is on.'
```