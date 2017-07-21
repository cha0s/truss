# Hooks page

*Generate the hooks page.*

```coffeescript
fs = require 'fs'

{Transform} = require 'stream'

Promise = require 'bluebird'

DoxPage = require '.'

module.exports = class DoxPageHooks extends DoxPage
```

Map hooks to source files.

```coffeescript
  buildHookMap: (transforms) ->

    hookMap = {}

    for key in ['invocations', 'implementations']
      for transform in transforms
        for item in transform[key]
          ((hookMap[item] ?= {})[key] ?= []).push transform.stream.file

    return hookMap
```

Load hook templates.

```coffeescript
  hookTemplates: (hooks) ->

    templates = {}

    promises = for hook in hooks
      do (hook) -> new Promise (resolve, reject) ->
```

###### TODO: Dynamic hook locations.

```coffeescript
        fs.readFile "packages/truss-dox/docs/hook/#{
          hook
        }.md", (error, output) ->
          if error?
            return reject error if error.code isnt 'ENOENT'
            console.warn "Missing template for #{hook}..."

          templates[hook] = output
          resolve()

    Promise.all(promises).then -> templates

  transformsOutput: (transforms) ->
    self = this

    wordingFor =
      implementation: 'implements'
      invocation: 'invoke'

    hookMap = @buildHookMap transforms
    @hookTemplates(hooks = Object.keys hookMap).then (templates) ->

      render = ''

      for hook in hooks.sort((l, r) -> if l < r then -1 else 1)
```

Hook name.

```coffeescript
        render += "## #{hook}\n\n"
```

Hook template description.

```coffeescript
        render += templates[hook] + '\n\n' if templates[hook]
```

Output the i(mplement|nvoc)ations.

```coffeescript
        for key in ['implementation', 'invocation']
          continue unless hookMap[hook][pluralKey = "#{key}s"]?

          render += '<div class="admonition note">\n'

          count = hookMap[hook][pluralKey].length
          render += "  <p class=\"admonition-title\">#{count} #{key}"
          render += 's' if count > 1

          render += '</p>\n'
          render += '  <table>\n'
```

Output each i(mplement|nvoc)ation.

```coffeescript
          instances = for file, index in hookMap[hook][pluralKey]

            sourceLink = self.linkToSource file

            """
<tr class="#{if index % 2 then 'odd' else 'even'}\">
  <td>
    <a href="../source/#{sourceLink}">#{file}</a>
  </td>
  <td align="right">
    <a href="../source/#{sourceLink}##{wordingFor[key]}-hook-#{self.uniqueId sourceLink, hook}">#{key}</a>
  </td>
</tr>
""".split('\n').map((e) -> "    #{e}").join('\n')

          render += instances.join '\n'

          render += '\n  </table>\n'
          render += '</div>'
          render += '\n\n'

      return render

  transformForStream: (stream) -> class HookTransform extends Transform

    constructor: (@processor, @stream) ->
      super null

      @implementations = []
      @invocations = []

    _transform: (chunk, encoding, done) ->
      line = chunk.toString 'utf8'

      if matches = line.match /^\s*# #### Implements hook `([^`]+)`/
        @implementations.push matches[1]

      if matches = line.match /^\s*# #### Invoke hook `([^`]+)`/
        @invocations.push matches[1]

      done()
```
