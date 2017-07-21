
path = require 'path'

config = require 'config'

class PackageManager

  @normalizePath: (path, capitalize = false) ->

    i8n = require 'inflection'

    parts = for part, i in path.split '/'
      i8n.camelize i8n.underscore(
        part.replace /[^\w]/g, '_'
        0 is i
      )

    i8n.camelize (i8n.underscore parts.join ''), not capitalize

  # ## PackageManager#constructor
  constructor: ->

    @_hookIndex = {}
    @_pkgIndex = {}

    @_packageList = []

  # ## PackageManager#invoke
  #
  # * (String) `hook` - The hook to invoke.
  #
  # * (Array) `args` - The arguments passed to the hook implementations.
  #
  # *Invoke a hook, heying the results by package implementations.*
  invoke: (hook, args...) ->
    results = {}
    for pkg in @packagesImplementing hook
      results[pkg] = @invokePackage pkg, hook, args...
    return results

  # ## PackageManager#invokeFlat
  #
  # * (String) `hook` - The hook to invoke.
  #
  # * (Array) `args` - The arguments passed to the hook implementations.
  #
  # *Invoke a hook, returning the results as a flattened array.*
  invokeFlat: (hook, args...) ->
    for pkg in @packagesImplementing hook
      @invokePackage pkg, hook, args...

  # ## PackageManager#invokePackage
  #
  # * (String) `pkg` - The package.
  #
  # * (String) `hook` - The hook to invoke.
  #
  # * (Array) `args` - The arguments passed to the hook implementation.
  #
  # *Invoke a hook, returning the result.*
  invokePackage: (pkg, hook, args...) -> @_pkgIndex?[pkg]?[hook]? args...

  # ## PackageManager#isPackageRegistered
  #
  # * (String) `pkg` - The package.
  #
  # *Check whether a package is registered.*
  isPackageRegistered: (pkg) -> -1 isnt @_packageList.indexOf pkg

  # ## PackageManager#packageImplements
  #
  # * (String) `pkg` - The package.
  #
  # * (String) `hook` - The hook to check.
  #
  # *Check whether a package implements a hook.*
  packageImplements: (pkg, hook) -> @_pkgIndex?[pkg]?[hook]?

  # ## PackageManager#packageList
  #
  # *Get the list of registered packages.*
  packageList: -> @_packageList

  # ## PackageManager#packagePath
  #
  # * (String) `pkg` - The package.
  #
  # *Get the filepath of a package.*
  packagePath: (pkg) ->

    path_ = config.get 'path'
    path.relative path_, path.dirname require.resolve pkg

  # ## PackageManager#packagesImplementing
  #
  # * (String) `hook` - The hook to check.
  #
  # *Get the list of registered packages implementing a hook.*
  packagesImplementing: (hook) -> @_hookIndex?[hook] ? []

  # ## PackageManager#registerPackage
  #
  # * (String) `pkg` - The package.
  #
  # *Register a package.*
  registerPackage: (pkg) ->
    return if @isPackageRegistered pkg

    try
      module_ = require pkg

    # Suppress missing package errors.
    catch error
      if error.toString() is "Error: Cannot find module '#{pkg}'"
        return

      throw error

    @_packageList.push pkg

    module_.pkgmanRegister? new PackageManager.Registrar(
      @_hookIndex, @_pkgIndex, pkg
    )

  # ## PackageManager#registerPackages
  #
  # * (Array of String) `pkgs` - The packages.
  #
  # *Register packages.*
  registerPackages: (pkgs) -> @registerPackage pkg for pkg in pkgs

  # ## PackageManager#unregisterPackage
  #
  # * (String) `pkg` - The package.
  #
  # *Unregister a package.*
  unregisterPackage: (pkg) ->
    return unless @isPackageRegistered pkg

    for hook of @_pkgIndex[pkg]

      if -1 isnt index = @_hookIndex[hook].indexOf pkg
        @_hookIndex[hook].splice index, 1
        delete @_hookIndex[hook] if @_hookIndex[hook].length is 0

    delete @_pkgIndex[pkg]

    index = @_packageList.indexOf pkg
    @_packageList.splice index, 1

    return

  # ## PackageManager#unregisterPackages
  #
  # * (Array of String) `pkgs` - The packages.
  #
  # *Unregister a list of packages.*
  unregisterPackages: (pkgs) -> @unregisterPackage pkg for pkg in pkgs

class PackageManager.Registrar

  constructor: (@_hookIndex, @_pkgIndex, @_path) ->

  path: -> @_path

  recur: (paths) ->
    for path_ in paths
      subpath = "#{@_path}/#{path_}"
      submodule = require subpath
      submodule.pkgmanRegister? new PackageManager.Registrar(
        @_hookIndex, @_pkgIndex, subpath
      )

  registerHook: (submodule, hook, impl) ->

    # If `submodule` was passed in, modify the path this hook is registered
    # against.
    if impl?

      path_ = "#{@_path}/#{submodule}"

    # Otherwise, fix up the args.
    else

      path_ = @_path
      impl = hook
      hook = submodule

    (@_hookIndex[hook] ?= []).push path_
    (@_pkgIndex[path_] ?= {})[hook] = impl

module.exports = new PackageManager()
module.exports.PackageManager = PackageManager
