# # Front-end system
#
# *Front-end abstraction: respond to client, render response, etc.*

_ = require 'lodash'
cheerio = require 'cheerio'

pkgman = require 'pkgman'

config = require 'config'
{Config} = config

exports.pkgmanRegister = (registrar) ->

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
