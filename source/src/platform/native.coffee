
```coffeescript

path = require 'path'
fs = require 'fs'

yaml = require 'js-yaml'

{Config} = require 'config'
pkgman = require 'pkgman'

module.exports = class NativePlatform

  exitHandler: ->
```

Set up exit hooks.

#### Invoke hook [`trussProcessExit`](../../../hooks#trussprocessexit)

```coffeescript
    process.on 'exit', -> pkgman.invoke 'trussProcessExit'

    process.on 'SIGINT', -> process.exit()
    process.on 'SIGTERM', -> process.exit()
    process.on 'unhandledException', -> process.exit()

  loadConfig: (config) ->

    config.set 'path', path.resolve "#{__dirname}/../.."

    config.set k, v for k, v of process.env

    settingsFilename = config.get 'path'
    settingsFilename += '/config/settings.yml'

    throw new Error '
      Settings file not found!
      You should copy config/default.settings.yml to config/settings.yml
    ' unless fs.existsSync settingsFilename

    settings = yaml.safeLoad fs.readFileSync settingsFilename, 'utf8'

    config.set k, v for k, v of settings

  exit: -> process.exit()
```
