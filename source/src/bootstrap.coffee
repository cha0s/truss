# Process bootstrap

*Bootstrap the application and ensure require paths are set
by default.*

```coffeescript
exports.bootstrap = ->
```

Ensure we have default require paths.

```coffeescript
  TRUSS_REQUIRE_PATH = if process.env.TRUSS_REQUIRE_PATH?
    process.env.TRUSS_REQUIRE_PATH
  else
    'custom:packages:src'
```

Integrate any NODE_PATH after the Truss require paths.

```coffeescript
  if process.env.NODE_PATH?
    TRUSS_REQUIRE_PATH += ":#{process.env.NODE_PATH}"
```

HACK ALERT: Use internal node.js structure to modify the require paths
on-the-fly.

```coffeescript
  module = require 'module'
  process.env['NODE_PATH'] = TRUSS_REQUIRE_PATH
  module._initPaths()

  return
```
