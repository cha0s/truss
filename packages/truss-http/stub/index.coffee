
Promise = require 'bluebird'

http = require 'http'

TrussHttpServerAbstract = require '../abstract'

# ## TrussHttpServerStub
#
# A little HTTP stub. Just barely implementing the abstract Truss HTTP
# server API.
module.exports = class TrussHttpServerStub extends TrussHttpServerAbstract

  # ## TrussHttpServerStub#constructor
  constructor: ->
    super

    @_server = http.createServer()

  # ## TrussHttpServerStub#listener
  #
  # *Listen for HTTP connections.*
  listener: ->
    self = this

    new Promise (resolve, reject) ->

      self._server.on 'error', reject

      self._server.once 'listening', ->
        self._server.removeListener 'error', reject
        resolve()

      # Bind to the listen target.
      listenTarget = self.config 'listenTarget'
      listenTarget = [listenTarget] unless Array.isArray listenTarget
      self._server.listen listenTarget...

  registerMiddleware: ->
    self = this

    super

    # Invoke the request middleware.
    @_server.on 'request', (req, res) ->
      self._requestMiddleware.dispatch req, res, ->

  server: -> @_server

  trustProxy: (proxyList) ->
