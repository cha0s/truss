# HTTP server stub implementation

*A barebones HT TP server implementation.*

```coffeescript
Promise = require 'bluebird'

http = require 'http'

TrussHttpServerAbstract = require '../abstract'
```

## TrussHttpServerStub

A little HTTP stub. Just barely implementing the abstract Truss HTTP
server API.

```coffeescript
module.exports = class TrussHttpServerStub extends TrussHttpServerAbstract
```

## TrussHttpServerStub#constructor

```coffeescript
  constructor: ->
    super

    @_server = http.createServer()
```

## TrussHttpServerStub#listener

*Listen for HTTP connections.*

```coffeescript
  listener: ->
    self = this

    new Promise (resolve, reject) ->

      self._server.on 'error', reject

      self._server.once 'listening', ->
        self._server.removeListener 'error', reject
        resolve()
```

Bind to the listen target.

```coffeescript
      listenTarget = self.config 'listenTarget'
      listenTarget = [listenTarget] unless Array.isArray listenTarget
      self._server.listen listenTarget...

  registerMiddleware: ->
    self = this

    super
```

Invoke the request middleware.

```coffeescript
    @_server.on 'request', (req, res) ->
      self._requestMiddleware.dispatch req, res, ->

  server: -> @_server

  trustProxy: (proxyList) ->
```
