# Documentation

*Build the documentation in `gh-pages`.*

```coffeescript
path = require 'path'

{fork, spawn} = require 'child_process'

{Transform} = require 'stream'

exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`trussDoxSourceList`](../../hooks#trussdoxsourcelist)

```coffeescript
  registrar.registerHook 'trussDoxSourceList', -> [
    '*.coffee'
    'src/**/*.coffee'
    'config/default.settings.yml'
    'packages/**/*.coffee'
  ]
```

#### Implements hook [`trussDoxSourceMarkdownTransform`](../../hooks#trussdoxsourcemarkdowntransform)

```coffeescript
  registrar.registerHook 'trussDoxSourceMarkdownTransform', ->
```

Implement a transform stream to convert a source using hash comments to
markdown. This applies to coffee and yaml files.

```coffeescript
    extensions: [
      'coffee', 'litcoffee'
      'yaml', 'yml'
    ]
    TransformClass: class HashCommentToMarkdown extends Transform

      constructor: (@processor, @stream) ->
        super null
```

Language to highlight in fenced code.

```coffeescript
        @fencing = if @stream.file.match /\.(?:lit)?coffee$/
          'coffeescript'
        else if @stream.file.match /\.ya?ml$/
          'yaml'

        @hanging = []
        @hasWrittenCode = false
        @commenting = false

        @on 'finish', => @unshift "```\n" if @hasWrittenCode and not @commenting

      _transform: (chunk, encoding, done) ->

        line = chunk.toString 'utf8'
```

Emit comment.

```coffeescript
        if '#'.charCodeAt(0) is line.trim().charCodeAt(0)
```

End fenced code.

```coffeescript
          @push "```\n\n" if @hasWrittenCode and not @commenting

          comment = line.trim().substr 2
```

Link hook i(nvoc|mplement)ation comments to the hook page.

```coffeescript
          matches = comment.match /^#### (I(?:nvoke|mplements)) hook `([^`]+)`/
          if matches

            parts = path.dirname(@stream.file).split('/')
            parts.push '' if 'index.coffee' isnt path.basename @stream.file
            backpath = parts.map(-> '..').join '/'

            @push "#### #{
              matches[1]
            } hook [`#{
              matches[2]
            }`](#{
              backpath
            }/hooks##{
              matches[2].toLowerCase()
            })\n"
```

Just pass the comment through.

```coffeescript
          else

            @push "#{comment}\n"

          @commenting = true
```

Emit code.

```coffeescript
        else

          @hanging = [] if @commenting
          @push "\n```#{@fencing}\n" if @commenting or not @hasWrittenCode

          if line.length is 0
            @hanging.push '' unless @commenting
          else
            @push "\n" for blank in @hanging
            @hanging = []
            @push "#{line}\n"

          @commenting = false
          @hasWrittenCode = true

        done()
```

#### Implements hook [`trussServerGruntConfig`](../../hooks#trussservergruntconfig)

```coffeescript
  registrar.registerHook 'trussServerGruntConfig', (gruntConfig, grunt) ->
```

Clean task.

```coffeescript
    gruntConfig.configureTask 'clean', 'truss-dox', [
      'mkdocs.yml'
      'docs/source'
      'docs/{hooks,packages,todos}.md'
      'gh-pages/*'
      '!gh-pages/.git'
      '!gh-pages/.gitignore'
    ]
```

Make sure the `ghh-pages` directory exists.

```coffeescript
    gruntConfig.registerTask 'truss-dox:prepareDirectory', ->
      grunt.file.mkdir 'gh-pages'
```

Generate dynamic documentation.

```coffeescript
    gruntConfig.registerTask 'truss-dox:dynamic', ->
      done = @async()

      {promise} = require "#{__dirname}/dynamic"
      promise.then(done).catch (error) -> grunt.fail.fatal "
        Dynamic documentation generation failed: #{error.stack}
      ", 1
```

Run mkdocs to generate the documentation in `gh-pages`.

```coffeescript
    gruntConfig.registerTask 'truss-dox:mkdocs', ->
      done = @async()

      spawn('mkdocs', ['build']).on 'close', (code) ->
        return done() if code is 0

        grunt.fail.fatal 'Running `mkdocs build` failed', code

    gruntConfig.registerTask 'truss-dox', [
       'truss-dox:prepareDirectory'
       'truss-dox:dynamic'
       'truss-dox:mkdocs'
    ]
```
