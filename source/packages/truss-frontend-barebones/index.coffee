# Barebones front-end implementation

*Build a simple HTML response.*

```coffeescript
_ = require 'lodash'

pkgman = require 'pkgman'

exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`trussFrontendRenderHtml`](../../hooks#trussfrontendrenderhtml)

```coffeescript
  registrar.registerHook 'trussFrontendRenderHtml', (req, res) ->

    {$} = res

    head = $('head')
```

Mobile-first!

```coffeescript
    head.append $('<meta>').attr 'charset', 'utf-8'
    head.append $('<meta>').attr(
      name: 'viewport'
      content: 'width=device-width, initial-scale=1.0'
    )
```

Pass through the config.

```coffeescript
    head.append $('<script>').html "window.__trussConfig = #{
      JSON.stringify res.clientConfig
    }"

    body = $('body')

    body.append $('<p>').text "Hello world!"
```
