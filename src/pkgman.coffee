
class PackageManager

  @normalizePath: (path) ->

  constructor: ->

    @_hookIndex = {}
    @_pathIndex = {}

    @_packageList = []

  invoke: (hook, args...) ->
    results = {}
    for path in @packagesImplementing hook
      results[path] = @invokePackage path, hook, args...
    return results

  invokeFlat: (hook, args...) ->
    for path in @packagesImplementing hook
      @invokePackage path, hook, args...

  invokePackage: (path, hook, args...) -> @_pathIndex?[path]?[hook]? args...

  isPackageRegistered: (path) -> -1 isnt @_packageList.indexOf path

  packagesImplementing: (hook) -> @_hookIndex?[hook] ? []

  registerPackage: (path) ->
    return if @isPackageRegistered path

    try
      module_ = require path

    # Suppress missing package errors.
    catch error
      if error.toString() is "Error: Cannot find module '#{path}'"
        return

      throw error

    @_packageList.push path

    module_.pkgmanRegister? new PackageManager.Registrar(
      @_hookIndex, @_pathIndex, path
    )

  registerPackages: (paths) -> @registerPackage path for path in paths

  unregisterPackage: (path) ->
    return unless @isPackageRegistered path

    for hook of @_pathIndex[path]

      if -1 isnt index = @_hookIndex[hook].indexOf path
        @_hookIndex[hook].splice index, 1
        delete @_hookIndex[hook] if @_hookIndex[hook].length is 0

    delete @_pathIndex[path]

    index = @_packageList.indexOf path
    @_packageList.splice index, 1

    return

  unregisterPackages: (paths) -> @unregisterPackage path for path in paths

class PackageManager.Registrar

  constructor: (@_hookIndex, @_pathIndex, @_path) ->

  path: -> @_path

  recur: (paths) ->
    for path in paths
      subpath = "#{@_path}/#{path}"
      submodule = require subpath
      submodule.pkgmanRegister? new PackageManager.Registrar(
        @_hookIndex, @_pathIndex, subpath
      )

  registerHook: (submodule, hook, impl) ->

    # If `submodule` was passed in, modify the path this hook is registered
    # against.
    if impl?

      path = "#{@_path}/#{submodule}"

    # Otherwise, fix up the args.
    else

      path = @_path
      impl = hook
      hook = submodule

    (@_hookIndex[hook] ?= []).push path
    (@_pathIndex[path] ?= {})[hook] = impl

module.exports = new PackageManager()
module.exports.PackageManager = PackageManager
