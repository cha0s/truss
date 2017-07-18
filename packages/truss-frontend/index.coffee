# # Front-end system
#
# *Front-end abstraction: respond to client, render response, etc.*

path = require 'path'

_ = require 'lodash'
cheerio = require 'cheerio'

pkgman = require 'pkgman'

config = require 'config'
{Config} = config

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `trussFrontendPackageTasks`.
  registrar.registerHook 'trussFrontendPackageTasks', (gruntConfig, grunt) ->

    gruntConfig.configureTask 'coffee', "truss-frontend-truss-frontend", files: [
      src: "packages/truss-frontend/client/require.coffee"
      dest: 'build/js/client/require.js'
    ]

    gruntConfig.registerTask "truss-frontend-truss-frontend", [
      "newer:coffee:truss-frontend-truss-frontend"
    ]

    return ["truss-frontend-truss-frontend"]

  # #### Implements hook `trussServerGruntConfig`.
  registrar.registerHook 'trussServerGruntConfig', (gruntConfig, grunt) ->

    # Cleaning rules.
    gruntConfig.configureTask 'clean', 'truss-frontend', ['build', 'frontend']

    # Build each package's frontend tasks.
    packageTasks = []
    for pkg in pkgman.packageList()

      if pkgman.packageImplements pkg, 'trussFrontendPackageTasks'
        tasks = pkgman.invokePackage(
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

        tasks = ["newer:coffee:truss-frontend-#{pkg}"]

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

  # #### Implements hook `trussHttpServerRequestMiddleware`.
  registrar.registerHook 'config', 'trussHttpServerRequestMiddleware', ->

    label: 'Build client configuration for request'

    middleware: [

      (req, res, next) ->

        res.clientConfig = clientConfig = new Config()

        # Gather client-side packages
        packagesLists = pkgman.invokeFlat 'trussFrontendPackageList', req, res
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

        next()

    ]

  # #### Implements hook `trussHttpServerRequestMiddleware`.
  registrar.registerHook 'render', 'trussHttpServerRequestMiddleware', ->

    label: 'Render delivery for request'

    middleware: [

      (req, res, next) ->

        res.$ = cheerio.load '''
<!doctype html><html><head></head><body></body></html>
'''

        pkgman.invoke 'trussFrontendRenderHtml', req, res
        res.delivery = res.$.html()

        next()

    ]
