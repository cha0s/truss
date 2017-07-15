# Native server application entry point.

```coffeescript
```

Ensure proper environment exists.

```coffeescript
require("#{__dirname}/src/bootstrap").bootstrap()

path = require 'path'
fs = require 'fs'

config = require 'config'
pkgman = require 'pkgman'
yaml = require 'js-yaml'
```

Set up exit hooks.

#### Invoke hook [`trussServerProcessExit`](../../hooks#trussserverprocessexit)

```coffeescript
process.on 'exit', -> pkgman.invoke 'trussServerProcessExit'

process.on 'SIGINT', -> process.exit()
process.on 'SIGTERM', -> process.exit()
process.on 'unhandledException', -> process.exit()
```

Set environment variables into config.

```coffeescript
config.set 'path', __dirname
config.set k, v for k, v of process.env
```

Read configuration file.

```coffeescript
settingsFilename = config.get 'path'
settingsFilename += '/config/settings.yml'

throw new Error '
  Settings file not found!
  You should copy config/default.settings.yml to config/settings.yml
' unless fs.existsSync settingsFilename

settings = yaml.safeLoad fs.readFileSync settingsFilename, 'utf8'
config.set k, v for k, v of settings
```

Spin up the server.

```coffeescript
require('main').start config, (error) ->
  return unless error?

  console.error require('errors').stack error
  process.exit 1
```
