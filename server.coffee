# # Native server application entry point.

# Fork the app to ensure proper environment exists.
{fork} = require "#{__dirname}/src/bootstrap"
unless fork()

  # Set platform to native.
  Platform = require 'platform'
  Platform.set 'native'

  # Spin up the server.
  require('main').start()
