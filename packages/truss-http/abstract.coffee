# # Abstract HTTP server
#
# *An abstract HTTP server interface.*

_ = require 'lodash'
Promise = require 'bluebird'

config = require 'config'
middleware = require 'middleware'
pkgman = require 'pkgman'

httpDebug = require('debug') 'truss:http'
httpMiddlewareDebug = require('debug') 'truss-silly:http:middleware'

# ## TrussHttpServerAbstract
#
# An abstract interface to be implemented by an HTTP server (e.g.
# [Express](source/packages/truss-http-express)).
module.exports = class TrussHttpServerAbstract

  # ## *constructor*
  #
  # *Create the server.*
  constructor: ->

    @_requestMiddleware = null
    @_routes = []

  # ## TrussHttpServerAbstract#addRoute
  #
  # *Add HTTP routes.*
  addRoute: (route) -> @_routes.push route

  # ## TrussHttpServerAbstract#config
  #
  # *Lookup a configuration value.*
  config: (key) -> config.get "packageConfig:truss-http:#{key}"

  # ## TrussHttpServerAbstract#listen
  #
  # *Listen for HTTP connections.*
  listen: ->
    self = this

    # Promise to be resolved when listening starts.
    promise = new Promise (resolve, reject) ->

      do tryListener = -> self.listener().done(
        resolve

        (error) ->
          return reject error unless 'EADDRINUSE' is error.code

          httpDebug 'HTTP listen target in use... retrying in 2 seconds'
          setTimeout tryListener, 2000

      )

    # Once listening, log about it.
    promise.then ->

      listenTarget = self.config 'listenTarget'
      listenTarget = [listenTarget] unless Array.isArray listenTarget

      if listenTarget.length is 1

        target = listenTarget[0]
        target = "port #{target}" if _.isNumber listenTarget[0]

      else

        target = "#{listenTarget[1]}:#{listenTarget[0]}"

      httpDebug "Shrub HTTP server up and running on #{target}!"

      # Post a message about it.
      global?.postMessage?(
        type: 'truss-http-server-start'
        listenTarget: listenTarget
      )

    return promise

  # ## TrussHttpServerAbstract#registerMiddleware
  #
  # *Gather and initialize HTTP middleware.*
  registerMiddleware: ->

    httpMiddlewareDebug '- Loading HTTP middleware...'

    httpMiddleware = @config('requestMiddleware').concat()

    # Make absolutely sure the requests are finalized.
    httpMiddleware.push 'truss-http'

    # #### Invoke hook `trussHttpServerRequestMiddleware`.
    #
    # Invoked every time an HTTP connection is established.
    @_requestMiddleware = middleware.fromHook(
      'trussHttpServerRequestMiddleware', httpMiddleware, this
    )

    httpMiddlewareDebug '- HTTP middleware loaded.'

  # Ensure any subclass implements these "pure virtual" methods.
  [
    'listener', 'server', 'trustProxy'
  ].forEach (method) -> TrussHttpServerAbstract::[method] = ->
    throw new ReferenceError(
      "TrussHttpServerAbstract::#{method} is a pure virtual method!"
    )
