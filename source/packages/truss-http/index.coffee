# HTTP server

*Manage HTTP connections.*


```coffeescript
_ = require 'lodash'

config = require 'config'
pkgman = require 'pkgman'

debug = require('debug') 'truss:http'
errors = require 'errors'

httpDebugSilly = require('debug') 'truss-silly:http'

httpServer = null

exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`trussServerBootstrapMiddleware`](../../hooks#trussserverbootstrapmiddleware)

```coffeescript
  registrar.registerHook 'trussServerBootstrapMiddleware', ->

    label: 'Bootstrap HTTP server'
    middleware: [

      (next) ->

        {module, listenTarget} = config.get 'packageConfig:truss-http'
```

Spin up the HTTP server, and initialize it.

```coffeescript
        Server = require module
        httpServer = new Server()
```

Compute the hostname if it isn't explicitly set.

```coffeescript
        unless config.get 'packageConfig:truss-http:hostname'

          listenTarget = config.get 'packageConfig:truss-http:listenTarget'
          listenTarget = [listenTarget] unless Array.isArray listenTarget

          if listenTarget.length is 1

            hostname = listenTarget[0]
            hostname = "localhost:#{hostname}" if _.isNumber hostname

          else

            hostname = "#{listenTarget[1]}:#{listenTarget[0]}"

          config.set 'packageConfig:truss-http:hostname', hostname
```

Mark proxies as trusted addresses.

```coffeescript
        httpServer.trustProxy(
          config.get 'packageConfig:truss-http:trustedProxies'
        )
```

#### Invoke hook [`trussHttpServerRoutes`](../../hooks#trusshttpserverroutes)

```coffeescript
        httpDebugSilly '- Registering routes...'
        for routeList in pkgman.invokeFlat 'trussHttpServerRoutes', httpServer
          for route in routeList
            route.verb ?= 'get'
            httpDebugSilly "- - #{route.verb.toUpperCase()} #{route.path}"
            httpServer.addRoute route
        httpDebugSilly '- Routes registered.'
```

Register middleware.

```coffeescript
        httpServer.registerMiddleware()
```

Listen...

```coffeescript
        httpServer.listen().then(-> next()).catch next

    ]
```

#### Implements hook [`trussHttpServerRequestMiddleware`](../../hooks#trusshttpserverrequestmiddleware)

```coffeescript
  registrar.registerHook 'trussHttpServerRequestMiddleware', (http) ->

    label: 'Finalize HTTP request'
    middleware: [

      (req, res, next) ->
```

If there's something to deliver, do it.

```coffeescript
        return res.end res.delivery if res.delivery?
```

Nothing specified for delivery? Return a 'not implemented' error.

```coffeescript
        res.writeHead 501
        res.end '<h1>501 Not Implemented</h1>'

      (error, req, res, next) ->
```

Emit error.

```coffeescript
        res.writeHead code = error.code ? 500
        res.end "<h1>#{
          code
        } Internal Server Error: #{
          errors.message error
        }</h1>"

    ]
```

#### Implements hook [`trussServerPackageConfig`](../../hooks#trussserverpackageconfig)

```coffeescript
  registrar.registerHook 'trussServerPackageConfig', ->
```

Module implementing the HTTP server.

```coffeescript
    module: 'truss-http/stub/instance'
```

The server hostname. Derived from `listenTarget` if not explicitly set.

```coffeescript
    hostname: ''
```

Middleware stack run for every request.

```coffeescript
    requestMiddleware: []
```

Where the server will be listening. This can be:

- A numeric port.
  `listenTarget: 4201`
- An array where the port is the first element, and the host is the
  second element: `listenTarget: [4201, '0.0.0.0']`

```coffeescript
    listenTarget: 4201
```

It's not uncommon to run your HTTP application behind a reverse proxy.
By default, we'll provide both ipv4 and embedded ipv6 addresses for
localhost. If a reverse proxy is running on the same machine you will
therefore automatically see the correct IP address in `req.normalizedIp`
which is provided to HTTP requests.

```coffeescript
    trustedProxies: [
      '127.0.0.1'
      '::ffff:127.0.0.1'
    ]

  registrar.recur [
    'stub'
  ]

exports.server = -> httpServer
```
