# Server application entry point

*Load the configuration, invoke the bootstrap hooks, and listen for signals
and process exit.* The core bootstrap phase injects environment into a
forked copy of the application including require paths to allow core and
custom packages to be included without qualification.

```coffeescript
config = require 'config'
debug = require('debug') 'truss:main'
middleware = require 'middleware'
pkgman = require 'pkgman'

exports.start = ->

  platform = require('platform').get()
```

Handle exiting the app.

```coffeescript
  platform.exitHandler()
```

Load configuration.

```coffeescript
  platform.loadConfig config
```

Register the configured packages.

```coffeescript
  pkgman.registerPackageList config.get 'packageList'
```

Load the packages' configuration settings and set into the default config.
#### Invoke hook [`trussConfigServer`](../../hooks#trussconfigserver)

```coffeescript
  packageConfig = new config.Config()
  for path, value of pkgman.invoke 'trussConfigServer'
    packageConfig.set path.replace(/\//g, ':'), value

  config.setDefaults packageConfig: packageConfig.toJSON()
```

Run the pre-bootstrap phase.
#### Invoke hook [`trussPreBootstrap`](../../hooks#trussprebootstrap)

```coffeescript
  debug 'Pre bootstrap started...'
  pkgman.invoke 'trussPreBootstrap'
  debug 'Pre bootstrap complete.'
```

Load the bootstrap middleware.
#### Invoke hook [`trussBootstrapMiddleware`](../../hooks#trussbootstrapmiddleware)

```coffeescript
  debug 'Bootstrap started...'
  bootstrapMiddleware = middleware.fromHook(
    'trussBootstrapMiddleware'
    config.get 'bootstrapMiddleware'
  )
```

Dispatch the bootstrap middleware and log if everything is okay.

```coffeescript
  bootstrapMiddleware.dispatch (error) ->
    return debug 'Bootstrap complete.' unless error?
```

Log any error and exit.

```coffeescript
    console.error errors.stack error
    platform.exit()
```
