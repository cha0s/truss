
exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `trussHttpServerRequestMiddleware`.
  registrar.registerHook 'trussHttpServerRequestMiddleware', (http) ->

    # Build a route lookup by path and verb.
    routeLookup = {}
    for route in http._routes
      routeLookup ?= {}
      routeLookup[route.path] ?= {}
      routeLookup[route.path][route.verb.toLowerCase()] = route.receiver

    label: 'HTTP routes'
    middleware: [

      (req, res, next) ->

        # Dispatch route if we find a path/verb match.
        return next() unless routeLookup[req.url]
        return next() unless routeLookup[req.url][req.method.toLowerCase()]
        routeLookup[req.url][req.method.toLowerCase()] req, res, next

    ]

