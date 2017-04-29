# # Native server application entry point.

# Fork the app to ensure proper environment exists.
{fork} = require "#{__dirname}/src/bootstrap"
unless fork()

  path = require 'path'
  fs = require 'fs'

  config = require 'config'
  pkgman = require 'pkgman'
  yaml = require 'js-yaml'

  # Set up exit hooks.
  #
  # #### Invoke hook `trussServerProcessExit`.
  process.on 'exit', -> pkgman.invoke 'trussServerProcessExit'

  process.on 'SIGINT', -> process.exit()
  process.on 'SIGTERM', -> process.exit()
  process.on 'unhandledException', -> process.exit()

  # Set environment variables into config.
  config.set 'path', __dirname
  config.set k, v for k, v of process.env

  # Read configuration file.
  settingsFilename = config.get 'path'
  settingsFilename += '/config/settings.yml'

  throw new Error '
    Settings file not found!
    You should copy config/default.settings.yml to config/settings.yml
  ' unless fs.existsSync settingsFilename

  settings = yaml.safeLoad fs.readFileSync settingsFilename, 'utf8'
  config.set k, v for k, v of settings

  # Spin up the server.
  require('main').start (error) ->

    console.error errors.stack error
    process.exit 1
