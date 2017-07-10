# # Server application entry point
#
# *Load the configuration, invoke the bootstrap hooks, and listen for signals
# and process exit.* The core bootstrap phase injects environment into a
# forked copy of the application including require paths to allow core and
# custom packages to be included without qualification.

debug = require('debug') 'truss:main'
middleware = require 'middleware'
pkgman = require 'pkgman'

exports.start = (config, fn) ->

  # Register the configured packages.
  pkgman.registerPackages config.get 'packageList'

  # Load the packages' configuration settings and set into the default config.
  # #### Invoke hook `trussServerPackageConfig`.
  packageConfig = new config.Config()
  for path, value of pkgman.invoke 'trussServerPackageConfig'
    packageConfig.set path.replace(/\//g, ':'), value
  config.setDefaults packageConfig: packageConfig.toJSON()

  # Run the pre-bootstrap phase.
  # #### Invoke hook `trussServerPreBootstrap`.
  debug 'Pre bootstrap started...'
  pkgman.invoke 'trussServerPreBootstrap'
  debug 'Pre bootstrap complete.'

  # Load the bootstrap middleware.
  # #### Invoke hook `trussServerBootstrapMiddleware`.
  debug 'Bootstrap started...'
  bootstrapMiddleware = middleware.fromHook(
    'trussServerBootstrapMiddleware'
    config.get 'serverBootstrapMiddleware'
  )

  # Dispatch the bootstrap middleware and log if everything is okay.
  bootstrapMiddleware.dispatch (error) ->
    debug 'Bootstrap complete.' unless error?

    # Finish the bootstrap.
    fn error
