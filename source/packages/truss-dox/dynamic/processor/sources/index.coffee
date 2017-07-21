# Abstract sources processor

*Abstract class to process the project sources, usually by transforming them
to a new form.*

```coffeescript
Promise = require 'bluebird'

module.exports = class SourcesProcessor

  constructor: (@streams) ->

  process: -> throw new Error(
    "SourcesProcessor::process is a pure virtual method"
  )

  streamsToTransforms: ->
    for stream in @streams
      Transform_ = @transformForStream stream
      stream.pipe transformStream = new Transform_ this, stream
      transformStream

  transformForStream: -> class NoTransform
    constructor: -> throw new Error(
      "SourceProcessor::Transform is a pure virtual class"
    )
```
