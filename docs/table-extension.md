# inmation.table-extension

Import library

```lua
require('inmation.table-extension')
```

---
## imap
The map() method creates a new array with the results of calling a provided function on every element in the calling array.

Ported from [Mozilla Developer Network - JavaScript Reference - Array - Map](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/map)

```lua
local numbers = { 1, 4, 9 }
local roots = table.imap(numbers, function(number)
    return math.sqrt(number)
end)
-- roots is { 1, 2, 3 }
```
---
## ireduce
The ireduce() method applies a function against an accumulator and each element in the array (from left to right) to reduce it to a single value.

Ported from [Mozilla Developer Network - JavaScript Reference - Array - Reduce](https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Global_Objects/Array/reduce)

Calculate summary:
```lua
local total = table.ireduce({ 0, 1, 2, 3 }, function(sum, value)
    return sum + value;
end, 0)
-- total is 6
```

Flatten array:
```lua
local flattened = table.ireduce({ {0, 1}, {2, 3}, {4, 5} }, function(a, b)
    return table.imerge(a, b)
end, {})
-- flattened { 0, 1, 2, 3, 4, 5 }
```

Map and Reduce:
```lua
local result = table.imap({ { x = 22}, { x = 42}  }, function(cur)
    return cur.x
end):ireduce(function(max, cur)
    return math.max(max, cur)
end, -math.huge)
-- result is 42
```
---