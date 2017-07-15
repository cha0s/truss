# mkdocs "page"

*Generate the mkdocs.yml. Not technically a page, but fits well enough
within the abstraction...*

```coffeescript
{Transform} = require 'stream'

_ = require 'lodash'

DoxPage = require './dox-page'
```

###### TODO: I think this should be done centrally, using an interface on each processor

```coffeescript
module.exports = class DoxPageMkdocs extends DoxPage
```

Build the source hierarchy.

```coffeescript
  buildHierarchy: (transforms) ->

    hierarchy = Source: {}

    for {stream: file: file} in transforms
      walk = hierarchy.Source
      parts = file.split '/'
      for part, i in parts
        if i is parts.length - 1
          walk[part] = "source/#{file}"
        else
          walk[part] ?= {}
          walk = walk[part]

    return hierarchy
```

Render the source hierarchy.

```coffeescript
  renderHierarchy: (hierarchy) ->

    output = []

    renderHierarchyInternal = (output, hierarchy, indent) ->
      if _.isString hierarchy
        output[output.length - 1] += " '#{hierarchy}'"
      else
        for k, v of hierarchy
          output.push "#{indent}- #{k}:"
          renderHierarchyInternal output, v, "#{indent}    "

    renderHierarchyInternal output, hierarchy, ''

    return output

  transformsOutput: (transforms) ->
    return @renderHierarchy(@buildHierarchy transforms).join '\n'

  transformForStream: (stream) -> class Passthrough extends Transform

    constructor: (@processor, @stream) ->
      super null

    _transform: (chunk, encoding, done) ->
      @push chunk
      done()
```
