# Native server application entry point.

```coffeescript
```

Fork the app to ensure proper environment exists.

```coffeescript
{fork} = require "#{__dirname}/src/bootstrap"
unless fork()
```

Set platform to native.

```coffeescript
  Platform = require 'platform'
  Platform.set 'native'
```

Spin up the server.

```coffeescript
  require('main').start()
```
