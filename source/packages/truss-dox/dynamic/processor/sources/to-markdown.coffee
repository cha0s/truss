# Markdown source pages

*Implementation of SourcesProcessor to convert source to markdown for easy
reading.*


```coffeescript
fs = require 'fs'
path = require 'path'

Promise = require 'bluebird'

{Transform} = require 'stream'

pkgman = require 'pkgman'

SourcesProcessor = require '.'

promiseForStream = (stream) ->
  new Promise (resolve, reject) ->
    stream.on 'error', reject
    stream.on 'close', resolve

module.exports = class SourcesToMarkdown extends SourcesProcessor

  constructor: ->
    super

    @extensionMap = {}

  buildDirectoryStructure: ->
```

Build the directory tree.

```coffeescript
    pathMap = {}
    for {file} in @streams
      parts = file.split '/'
      for i in [0...parts.length]
        pathMap["packages/truss-dox/docs/source/#{
          parts.slice(0, i).join '/'
        }"] = true
```

This could be made async...

```coffeescript
    for path_ of pathMap
      try
        fs.mkdirSync path_
      catch error
        throw error if 'EEXIST' isnt error.code

  buildExtensionMap: ->
```

#### Invoke hook [`trussDoxSourceMarkdownTransform`](../../../../../../hooks#trussdoxsourcemarkdowntransform)

```coffeescript
    @extensionMap = {}
    for transform in pkgman.invokeFlat 'trussDoxSourceMarkdownTransform'
      for extension in transform.extensions
        @extensionMap[extension] = transform.TransformClass

  processMarkdown: ->
```

Convert to markdown.

```coffeescript
    transforms = @streamsToTransforms @streams
    promises = for stream, i in @streams
      destination = fs.createWriteStream "packages/truss-dox/docs/source/#{
        stream.file
      }"
      transforms[i].pipe destination
      promiseForStream destination

    Promise.all promises

  process: ->

    @buildDirectoryStructure()
    @buildExtensionMap()
    @processMarkdown()

  transformForStream: (stream) ->
```

Handler for this extension?

```coffeescript
    extension = path.extname(stream.file).substr 1
    TransformClass = if @extensionMap[extension]?
      @extensionMap[extension]

    else
```

Otherwise pass the source through as markdown: one big fenced code
block.

```coffeescript
      class PassthroughToMarkdown extends Transform

        constructor: ->
          super null

          @push "```\n"
          @on 'finish', => @unshift "```no-highlight\n"

        _transform: (chunk, encoding, done) ->
          @push "#{chunk.toString 'utf8'}\n"
          done()
```
