# # Front-end system
#
# *Front-end abstraction: respond to client, render response, etc.*

path = require 'path'

_ = require 'lodash'
cheerio = require 'cheerio'

pkgman = require 'pkgman'

config = require 'config'
{Config} = config

assets = null

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `trussFrontendAssetsMiddleware`.
  registrar.registerHook 'trussFrontendAssetsMiddleware', ->

    label: 'Modules'
    middleware: [

      (req, assets, next) ->

        # Config script.
        clientConfig = new Config()

        # Gather client-side packages
        packagesLists = pkgman.invokeFlat 'trussFrontendPackageList', req
        packageList = _.flatten packagesLists

        # Use package list to build client package configuration.
        clientPackageConfig = new Config()
        for path in pkgman.packagesImplementing 'trussFrontendPackageConfig'
          clientPackageConfig.set(
            path.replace /\//g, ':'
            pkgman.invokePackage path, 'trussFrontendPackageConfig', req
          )

        clientConfig.set 'packageList', config.get 'packageList'
        clientConfig.set 'packageConfig', clientPackageConfig.toJSON()

        # Assign the config variable.
        assets.scripts.push
          type: 'inline'
          data: "window.__trussConfig = #{
            JSON.stringify clientConfig
          }"

        # Modules.
        if 'production' is config.get 'NODE_ENV'
          assets.scripts.push '/frontend/modules.min.js'
        else
          assets.scripts.push '/frontend/modules.js'

        next()

    ]

  # #### Implements hook `trussFrontendPackageTasks`.
  registrar.registerHook 'trussFrontendPackageTasks', (gruntConfig, grunt) ->

    # Watch rule.
    gruntConfig.configureTask 'watch', 'truss-frontend-truss-frontend', {
      files: ["packages/truss-frontend/client/require.coffee"]
      tasks: ['build:truss-frontend']
      options: livereload: true
    }

    # Build the require stub out-of-band, it shouldn't be included as a
    # regular client module.
    gruntConfig.configureTask 'coffee', "truss-frontend-truss-frontend", files: [
      src: "packages/truss-frontend/client/require.coffee"
      dest: 'build/js/client/require.js'
    ]

    return 'newer:coffee:truss-frontend-truss-frontend'

  # #### Implements hook `trussServerGruntConfig`.
  registrar.registerHook 'trussServerGruntConfig', (gruntConfig, grunt) ->

    # Cleaning rules.
    gruntConfig.configureTask 'clean', 'truss-frontend', ['build', 'frontend']

    # Build each package's frontend tasks.
    packageTasks = []
    for pkg in pkgman.packageList()

      tasks = if pkgman.packageImplements pkg, 'trussFrontendPackageTasks'
        pkgman.invokePackage(
          pkg, 'trussFrontendPackageTasks', gruntConfig, grunt
        )

      else

        # Watch rules.
        gruntConfig.configureTask 'watch', "truss-frontend-#{pkg}", {
          files: ["#{pkgman.packagePath pkg}/client/**/*.coffee"]
          tasks: ['build:truss-frontend']
          options: livereload: true
        }

        # Compilation rules.
        gruntConfig.configureTask 'coffee', "truss-frontend-#{pkg}", files: [
          src: "#{pkgman.packagePath pkg}/client/**/*.coffee"
          dest: 'build/js/client/raw'
          expand: true
          ext: '.js'
        ]

        "newer:coffee:truss-frontend-#{pkg}"

      gruntConfig.registerTask 'truss-frontend-packages', tasks

    # Browserify modules.
    gruntConfig.configureTask 'browserify', 'truss-node-path', {
      src: ['node_modules/path-browserify/index.js']
      dest: 'build/js/client/raw/path.js'
      options: browserifyOptions: standalone: 'path'
    }
    gruntConfig.registerTask 'truss-frontend-browserify', [
      'newer:browserify:truss-node-path'
    ]

    # Wrap all modules with the require function.
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

          # Slice past the number of slashes in `build/js/client/raw`.
          modulePath = filepath.split('/').slice(4).join '/'

          # Little acrobatics to handle root-level paths.
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

    # Concatenate the require stub to the bottom of the modules.
    gruntConfig.configureTask 'concat', 'truss-frontend', files: [
      src: [
        'build/js/client/modules-raw.js'
        'build/js/client/require.js'
      ]
      dest: 'build/js/client/modules-raw-with-require.js'
    ]

    # Wrap the whole thing in an IIFE and define the _requires object to hold
    # all module implementations.
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

    # Minimize the module sources.
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

  # #### Implements hook `trussFrontendPackageConfig`.
  registrar.registerHook 'trussFrontendPackageConfig', ->

  # #### Implements hook `trussFrontendPackageList`.
  registrar.registerHook 'trussFrontendPackageList', (path) ->

  # #### Implements hook `trussHttpServerRoutes`.
  registrar.registerHook 'config', 'trussHttpServerRoutes', -> [
    path: '/frontend/modules.js'
    receiver: (req, res, next) -> require('fs').createReadStream(
      "#{config.get 'path'}/frontend/modules.js"
    ).pipe res
  ]

  # #### Implements hook `trussHttpServerRequestMiddleware`.
  registrar.registerHook 'trussHttpServerRequestMiddleware', ->

    debug = require('debug') 'truss-silly:assets:middleware'

    middleware = require 'middleware'

    # #### Invoke hook `trussFrontendAssetsMiddleware`.
    debug '- Loading asset middleware...'

    assetsMiddleware = middleware.fromConfig 'truss-frontend:assetsMiddleware'

    debug '- Asset middleware loaded.'

    label: 'Serve frontend'

    middleware: [

      (req, res, next) ->

        $ = res.$ = cheerio.load '''
<!doctype html><html><head></head><body></body></html>
'''

        # Add mobile-first tags.
        head = $('head')
        head.append $('<meta>').attr 'charset', 'utf-8'
        head.append $('<meta>').attr(
          name: 'viewport'
          content: 'width=device-width, initial-scale=1.0'
        )

        # Gather assets.
        body = $('body')
        assets = scripts: [], styleSheets: []
        assetsMiddleware.dispatch req, assets, (error) ->
          return next error if error?

          # Inject scripts.
          for script in assets.scripts
            script = type: 'src', data: script if _.isString script

            switch script.type

              when 'src'
                body.append $('<script>').attr(
                  'src', script.data
                  type: 'text/javascript'
                )

              when 'inline'
                body.append $('<script>').html script.data

          # Inject CSS.
          for styleSheet in assets.styleSheets
            body.append $('<style>').attr(
              href: styleSheet
              rel: 'stylesheet'
            )

          # Build the HTML and serve it.
          res.delivery = res.$.html()
          next()

    ]

  # #### Implements hook `trussServerPackageConfig`.
  registrar.registerHook 'trussServerPackageConfig', ->

    assetsMiddleware: [
      'truss-frontend'
    ]
