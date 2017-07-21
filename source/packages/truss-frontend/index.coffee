# Front-end system

*Front-end abstraction: respond to client, render response, etc.*


```coffeescript
path = require 'path'

_ = require 'lodash'
cheerio = require 'cheerio'

pkgman = require 'pkgman'

config = require 'config'
{Config} = config

assets = null

exports.pkgmanRegister = (registrar) ->
```

#### Implements hook [`trussFrontendAssetsMiddleware`](../../hooks#trussfrontendassetsmiddleware)

```coffeescript
  registrar.registerHook 'trussFrontendAssetsMiddleware', ->

    label: 'Modules'
    middleware: [

      (req, assets, next) ->
```

Config script.

```coffeescript
        clientConfig = new Config()
```

Use package list to build client package configuration.

```coffeescript
        clientPackageConfig = new Config()
        for path in pkgman.packagesImplementing 'trussFrontendPackageConfig'
          clientPackageConfig.set(
            path.replace /\//g, ':'
            pkgman.invokePackage path, 'trussFrontendPackageConfig', req
          )

        clientConfig.set 'packageList', config.get 'packageList'
        clientConfig.set 'packageConfig', clientPackageConfig.toJSON()
```

Assign the config variable.

```coffeescript
        assets.scripts.push
          type: 'inline'
          data: "window.__trussConfig = #{
            JSON.stringify clientConfig
          }"
```

Modules.

```coffeescript
        if 'production' is config.get 'NODE_ENV'
          assets.scripts.push '/frontend/modules.min.js'
        else
          assets.scripts.push '/frontend/modules.js'
```

Serve livereload script if we aren't running in production mode.

```coffeescript
        unless 'production' is config.get 'NODE_ENV'
          [hostname] = config.get('packageConfig:truss-http:hostname').split ':'
          assets.scripts.push "http://#{hostname}:35729/livereload.js"

        next()

    ]
```

#### Implements hook [`trussFrontendPackageTasks`](../../hooks#trussfrontendpackagetasks)

```coffeescript
  registrar.registerHook 'trussFrontendPackageTasks', (gruntConfig, grunt) ->
```

Watch rule.

```coffeescript
    gruntConfig.configureTask 'watch', 'truss-frontend-truss-frontend', {
      files: ["packages/truss-frontend/client/require.coffee"]
      tasks: ['build:truss-frontend']
      options: livereload: true
    }
```

Build the require stub out-of-band, it shouldn't be included as a
regular client module.

```coffeescript
    gruntConfig.configureTask 'coffee', "truss-frontend-truss-frontend", files: [
      src: "packages/truss-frontend/client/require.coffee"
      dest: 'build/js/client/require.js'
    ]

    return 'newer:coffee:truss-frontend-truss-frontend'
```

#### Implements hook [`trussServerGruntConfig`](../../hooks#trussservergruntconfig)

```coffeescript
  registrar.registerHook 'trussServerGruntConfig', (gruntConfig, grunt) ->
```

Cleaning rules.

```coffeescript
    gruntConfig.configureTask 'clean', 'truss-frontend', ['build', 'frontend']
```

Build each package's frontend tasks.

```coffeescript
    packageTasks = []
    for pkg in pkgman.packageList()

      tasks = if pkgman.packageImplements pkg, 'trussFrontendPackageTasks'
        pkgman.invokePackage(
          pkg, 'trussFrontendPackageTasks', gruntConfig, grunt
        )

      else
```

Watch rules.

```coffeescript
        gruntConfig.configureTask 'watch', "truss-frontend-#{pkg}", {
          files: ["#{pkgman.packagePath pkg}/client/**/*.coffee"]
          tasks: ['build:truss-frontend']
          options: livereload: true
        }
```

Compilation rules.

```coffeescript
        gruntConfig.configureTask 'coffee', "truss-frontend-#{pkg}", files: [
          src: "#{pkgman.packagePath pkg}/client/**/*.coffee"
          dest: 'build/js/client/raw'
          expand: true
          ext: '.js'
        ]

        "newer:coffee:truss-frontend-#{pkg}"

      gruntConfig.registerTask 'truss-frontend-packages', tasks
```

Browserify modules.

```coffeescript
    gruntConfig.configureTask 'browserify', 'truss-node-path', {
      src: ['node_modules/path-browserify/index.js']
      dest: 'build/js/client/raw/path.js'
      options: browserifyOptions: standalone: 'path'
    }
    gruntConfig.registerTask 'truss-frontend-browserify', [
      'newer:browserify:truss-node-path'
    ]
```

Wrap all modules with the require function.

```coffeescript
    gruntConfig.configureTask(
      'wrap', 'truss-frontend'

      files: [
        src: [
          'build/js/client/raw/**/*.js'
        ]
        dest: 'build/js/client/modules-raw.js'
      ]
      options:
        indent: '  '
        wrapper: (filepath) ->
```

Slice past the number of slashes in `build/js/client/raw`.

```coffeescript
          modulePath = filepath.split('/').slice(4).join '/'
```

Little acrobatics to handle root-level paths.

```coffeescript
          dirname = path.dirname modulePath
          if '.' is dirname = path.dirname modulePath
            dirname = ''
          else
            dirname += '/'
          basename = path.basename modulePath, path.extname modulePath

          [
            """
_requires['#{
  dirname
}#{
  basename
}'] = function(module, exports, require, __dirname, __filename) {


"""
            """

};


"""
          ]

    )
```

Concatenate the require stub to the bottom of the modules.

```coffeescript
    gruntConfig.configureTask 'concat', 'truss-frontend', files: [
      src: [
        'build/js/client/modules-raw.js'
        'build/js/client/require.js'
      ]
      dest: 'build/js/client/modules-raw-with-require.js'
    ]
```

Wrap the whole thing in an IIFE and define the _requires object to hold
all module implementations.

```coffeescript
    gruntConfig.configureTask(
      'wrap', 'truss-frontend-modules'

      files: [
        src: [
          'build/js/client/modules-raw-with-require.js'
        ]
        dest: 'frontend/modules.js'
      ]
      options:
        indent: '  '
        wrapper: [
          '(function() {\n\n  var _requires = {};\n\n\n'
          '\n\n})();\n\n'
        ]

    )
```

Minimize the module sources.

```coffeescript
    gruntConfig.configureTask 'uglify', 'truss-frontend', files: [
      src: [
        'frontend/modules.js'
      ]
      dest: 'frontend/modules.min.js'
    ]

    gruntConfig.registerTask 'production', ['uglify:truss-frontend']

    gruntConfig.registerTask 'build:truss-frontend', [
      'truss-frontend-packages'
      'truss-frontend-browserify'
      'newer:wrap:truss-frontend'
      'newer:concat:truss-frontend'
      'newer:wrap:truss-frontend-modules'
    ]

    gruntConfig.registerTask 'build', ['build:truss-frontend']

    gruntConfig.loadNpmTasks [
      'grunt-browserify'
      'grunt-contrib-clean'
      'grunt-contrib-coffee'
      'grunt-contrib-concat'
      'grunt-contrib-uglify'
      'grunt-contrib-watch'
      'grunt-newer'
      'grunt-wrap'
    ]
```

#### Implements hook [`trussHttpServerRoutes`](../../hooks#trusshttpserverroutes)

```coffeescript
  registrar.registerHook 'config', 'trussHttpServerRoutes', -> [
    path: '/frontend/modules.js'
    receiver: (req, res, next) -> require('fs').createReadStream(
      "#{config.get 'path'}/frontend/modules.js"
    ).pipe res
  ]
```

#### Implements hook [`trussHttpServerRequestMiddleware`](../../hooks#trusshttpserverrequestmiddleware)

```coffeescript
  registrar.registerHook 'trussHttpServerRequestMiddleware', ->

    debug = require('debug') 'truss-silly:assets:middleware'

    middleware = require 'middleware'
```

#### Invoke hook [`trussFrontendAssetsMiddleware`](../../hooks#trussfrontendassetsmiddleware)

```coffeescript
    debug '- Loading asset middleware...'

    assetsMiddleware = middleware.fromConfig 'truss-frontend:assetsMiddleware'

    debug '- Asset middleware loaded.'

    label: 'Serve frontend'

    middleware: [

      (req, res, next) ->

        $ = res.$ = cheerio.load '''
<!doctype html><html><head></head><body></body></html>
'''
```

Add mobile-first tags.

```coffeescript
        head = $('head')
        head.append $('<meta>').attr 'charset', 'utf-8'
        head.append $('<meta>').attr(
          name: 'viewport'
          content: 'width=device-width, initial-scale=1.0'
        )
```

Gather assets.

```coffeescript
        body = $('body')
        assets = scripts: [], styleSheets: []
        assetsMiddleware.dispatch req, assets, (error) ->
          return next error if error?
```

Inject scripts.

```coffeescript
          for script in assets.scripts
            if _.isString script
              script = type: 'remote', data: script

            $script = $('<script>').attr type: 'text/javascript'

            body.append switch script.type

              when 'remote'
                $script.attr src: script.data

              when 'inline'
                $script.html script.data
```

Inject CSS.

```coffeescript
          for styleSheet in assets.styleSheets
            if _.isString styleSheet
              styleSheet = type: 'remote', data: styleSheet

            body.append switch styleSheet.type

              when 'remote'
                $('<link>').attr rel: 'stylesheet', href: styleSheet.data

              when 'inline'
                $('<style>').attr(type: 'text/css').html styleSheet.data
```

Build the HTML and serve it.

```coffeescript
          res.delivery = res.$.html()
          next()

    ]
```

#### Implements hook [`trussServerPackageConfig`](../../hooks#trussserverpackageconfig)

```coffeescript
  registrar.registerHook 'trussServerPackageConfig', ->

    assetsMiddleware: [
      'truss-frontend'
    ]
```
