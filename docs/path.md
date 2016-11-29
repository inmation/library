## inmation.path

Import library

```lua
local pathLib = require('inmation.path')
```

#### pathLib.join
Joins multiple string argument to a proper inmation path string.

```lua
local parentPath = '/System/Core/Folder01'
local result = pathLib.join(parentPath, 'Sensor', 'Measurement')
-- result is '/System/Core/Folder01/Sensor/Measurement'
```

#### pathLib.parentPath
Parse the parent part of the given path string.

```lua
local result = pathLib.parentPath('/System/Core/Folder01/Sensor/Measurement')
-- result is '/System/Core/Folder01/Sensor'
```

#### pathLib.sanitize
Removes multiple slashes '//' and the trailing slash.

```lua
local result = pathLib.sanitize('/System/Core/Folder01//Sensor//Measurement/')
-- result is '/System/Core/Folder01/Sensor/Measurement'
```