# TODOs page

*Generate the TODOs page.*


```coffeescript
{Transform} = require 'stream'

DoxPage = require '.'

module.exports = class DoxPageTodos extends DoxPage
```

Implement a Transform stream to accumulate TODOs from a source file. Also
caches lines to be able to build context around each TODO item.

```coffeescript
  transformForStream: (stream) -> class TodoTransform extends Transform

    @CONTEXT = 4

    constructor: (@processor, @stream) ->
      super null

      @context = []
      @lines = []

    _transform: (chunk, encoding, done) ->
```

Track all lines, for later context.

```coffeescript
      @context.push line = chunk.toString 'utf8'
```

Track all TODOs.

```coffeescript
      @lines.push @context.length - 1 if line.match /^\s*# ###### TODO/

      done()

    todos: ->
```

Chop out context for each TODO, and include it with the line number.

```coffeescript
      for line in @lines
        start = Math.max 0, line - TodoTransform.CONTEXT
        end = Math.min @context.length - 1, line + TodoTransform.CONTEXT

        line: line
        context: @context.slice start, end

    output: ->

      outputs = for todo in @todos()
```

###### TODO: Dynamic...

```coffeescript
        highlight = if @stream.file.match /\.(?:lit)?coffee$/
           'coffeescript'
        else if @stream.file.match /\.js$/
          'javascript'
        else
          'no-highlight'

        output = "\n---\n\n```#{highlight}\n"

        for line, index in todo.context
```

If this is the line with the TODO, parse the ID from the TODO
item text, and render it as h2 (TODO are h6) to increase
visibility.

```coffeescript
          if index is TodoTransform.CONTEXT
            output += "```\n\n#{line.trim().slice 6}\n\n```#{highlight}"
          else
            output += line
          output += '\n'

        output += '```\n\n'

        sourceLink = @processor.linkToSource @stream.file
```

The link to the TODO in the source file.

```coffeescript
        output += "[the above found in #{
          @stream.file
        }:#{
          todo.line
        }](source/#{
          sourceLink
        }##{
          @processor.uniqueId(
            sourceLink, todo.context[TodoTransform.CONTEXT]
          )
        })"

      outputs.join '\n'
```
