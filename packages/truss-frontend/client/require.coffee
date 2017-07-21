# # Require system for browser.
#
# *Implement require in the spirit of NodeJS.*

# Resolve the module name.
_resolveModuleName = (name, parentFilename) ->

  # ###### TODO: `NODE_PATH` implementation.
  # Strip `/index` from the end, if necessary.
  checkModuleName = (name) ->
    return name if _requires[name]?
    return "#{name}/index" if _requires["#{name}/index"]?

  # Absolute path match?
  return checked if (checked = checkModuleName name)?

  # Resolve relative paths. We have to check methods on `path`. See below for
  # more.
  path = _require 'path'
  return checked if (checked = checkModuleName(
    path.resolve(path.dirname(parentFilename), name).substr 1
  ))? if path.dirname? and path.resolve?

  # Oops, nothing resolved...
  throw new Error "Cannot find module '#{name}'"

# Internal require function. Uses the parent filename to resolve relative
# paths.
_require = (name, parentFilename) ->

  # Module inclusion is cached.
  unless _requires[name = _resolveModuleName name, parentFilename].module?

    # Extract the module function ahead of time, so we can set up
    # module/exports and assign it to the old value. Setting this up ahead of
    # time avoids cycles.
    f = _requires[name]
    exports = {}
    module = exports: exports
    _requires[name] = module: module

    # Include `path`, you may observe that this is dangerous because we're
    # within the require system itself. This is correct and we have to check
    # for `dirname` to ensure the object has been required and populated.
    path = _require 'path'
    __dirname = (path.dirname? name) ? ''
    __filename = name

    # Execute the top-level module function, passing in all of our objects.
    f(
      module, exports, (name) -> _require name, __filename
      __dirname, __filename
    )

  _requires[name].module.exports

# Export require API.
@require = (name) -> _require name, ''
