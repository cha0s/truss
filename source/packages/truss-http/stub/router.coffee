# HTTP server stub - Router

*Extremely simple and naive routing*


```coffeescript
exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`trussHttpServerRequestMiddleware`](../../../../hooks#trusshttpserverrequestmiddleware)

```coffeescript
  registrar.registerHook 'trussHttpServerRequestMiddleware', (http) ->
```

Build a route lookup by path and verb.

```coffeescript
    routeLookup = {}
    for route in http._routes
      routeLookup ?= {}
      routeLookup[route.path] ?= {}
      routeLookup[route.path][route.verb.toLowerCase()] = route.receiver

    label: 'HTTP routes'
    middleware: [

      (req, res, next) ->
```

Dispatch route if we find a path/verb match.

```coffeescript
        return next() unless routeLookup[req.url]
        return next() unless routeLookup[req.url][req.method.toLowerCase()]
        routeLookup[req.url][req.method.toLowerCase()] req, res, next

    ]
```