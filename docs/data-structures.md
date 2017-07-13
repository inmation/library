# inmation.data-structures

Library containing:
- Queue

---
## Queue

```lua
local Queue = require('inmation.data-structures').Queue
local queue = Queue.new()

-- Add the object in the queue.
queue:push({ ["hello"] = "World" })

-- Fetch object without removing it from the queue.
local obj = queue:peek()
-- obj is 

-- Fetch object and remove it from the queue.
local obj = queue:pop()

-- Return the number of objects in the queue.
local num = queue:length()
```

Example:

```lua
local Queue = require('inmation.data-structures').Queue
local queue = Queue.new()

queue:push("Hello")
queue:push({ ["Hello"] = "World" })

local length = queue:length()
-- length is 2

local obj = queue:pop()
-- obj is "Hello"

queue:push("inmation")

obj = queue:pop()
-- obj is { "Hello": "World" }

length = queue:length()
-- length = 1

obj = queue:peek()
-- obj is "inmation"

obj = queue:pop()
-- obj is "inmation"

queue:pop()
-- Error will be thrown because there is no more object in queue.

length = queue:length()
-- length = 0
```
---