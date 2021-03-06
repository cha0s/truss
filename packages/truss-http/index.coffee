# # HTTP server
#
# *Manage HTTP connections.*

_ = require 'lodash'

config = require 'config'
pkgman = require 'pkgman'

debug = require('debug') 'truss:http'
errors = require 'errors'

httpDebugSilly = require('debug') 'truss-silly:http'

httpServer = null

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `trussServerBootstrapMiddleware`.
  registrar.registerHook 'trussServerBootstrapMiddleware', ->

    label: 'Bootstrap HTTP server'
    middleware: [

      (next) ->

        {module, listenTarget} = config.get 'packageConfig:truss-http'

        # Spin up the HTTP server, and initialize it.
        Server = require module
        httpServer = new Server()

        # Compute the hostname if it isn't explicitly set.
        unless config.get 'packageConfig:truss-http:hostname'

          listenTarget = config.get 'packageConfig:truss-http:listenTarget'
          listenTarget = [listenTarget] unless Array.isArray listenTarget

          if listenTarget.length is 1

            hostname = listenTarget[0]
            hostname = "localhost:#{hostname}" if _.isNumber hostname

          else

            hostname = "#{listenTarget[1]}:#{listenTarget[0]}"

          config.set 'packageConfig:truss-http:hostname', hostname

        # Mark proxies as trusted addresses.
        httpServer.trustProxy(
          config.get 'packageConfig:truss-http:trustedProxies'
        )

        # #### Invoke hook `trussHttpServerRoutes`.
        httpDebugSilly '- Registering routes...'
        for routeList in pkgman.invokeFlat 'trussHttpServerRoutes', httpServer
          for route in routeList
            route.verb ?= 'get'
            httpDebugSilly "- - #{route.verb.toUpperCase()} #{route.path}"
            httpServer.addRoute route
        httpDebugSilly '- Routes registered.'

        # Register middleware.
        httpServer.registerMiddleware()

        # Listen...
        httpServer.listen().then(-> next()).catch next

    ]

  # #### Implements hook `trussHttpServerRequestMiddleware`.
  registrar.registerHook 'trussHttpServerRequestMiddleware', (http) ->

    label: 'Finalize HTTP request'
    middleware: [

      (req, res, next) ->

        # If there's something to deliver, do it.
        return res.end res.delivery if res.delivery?

        # Nothing specified for delivery? Return a 'not implemented' error.
        res.writeHead 501
        res.end '<h1>501 Not Implemented</h1>'

      (error, req, res, next) ->

        # Emit error.
        res.writeHead code = error.code ? 500
        res.end "<h1>#{
          code
        } Internal Server Error: #{
          errors.message error
        }</h1>"

    ]

  # #### Implements hook `trussServerPackageConfig`.
  registrar.registerHook 'trussServerPackageConfig', ->

    # Module implementing the HTTP server.
    module: 'truss-http/stub/instance'

    # The server hostname. Derived from `listenTarget` if not explicitly set.
    hostname: ''

    # Middleware stack run for every request.
    requestMiddleware: []

    # Where the server will be listening. This can be:
    #
    # - A numeric port.
    #   `listenTarget: 4201`
    # - An array where the port is the first element, and the host is the
    #   second element: `listenTarget: [4201, '0.0.0.0']`
    listenTarget: 4201

    # It's not uncommon to run your HTTP application behind a reverse proxy.
    # By default, we'll provide both ipv4 and embedded ipv6 addresses for
    # localhost. If a reverse proxy is running on the same machine you will
    # therefore automatically see the correct IP address in `req.normalizedIp`
    # which is provided to HTTP requests.
    trustedProxies: [
      '127.0.0.1'
      '::ffff:127.0.0.1'
    ]

  registrar.recur [
    'stub'
  ]

exports.server = -> httpServer
