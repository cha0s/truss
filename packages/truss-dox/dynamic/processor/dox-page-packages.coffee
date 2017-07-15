# # Packages page
#
# *Generate the packages page.*

path = require 'path'

{Transform} = require 'stream'

DoxPage = require './dox-page'

module.exports = class DoxPagePackages extends DoxPage

  # Sort files by package.
  sortFilesByPackage: (transforms) ->

    packages = {}

    for transform in transforms
      parts = transform.stream.file.split '/'
      continue if parts[0] isnt 'packages'
      (packages[parts[1]] ?= []).push transform.stream.file

    return packages

  # Create a map to lookup transforms by filename.
  transformsFileMap: (transforms) ->
    fileMap = {}
    fileMap[transform.stream.file] = transform for transform in transforms
    return fileMap

  # Lookup index file for a package.
  packageIndex: (package_, files) ->

    packageIndex = ''

    for file in files
      dirname = path.dirname file
      basename = path.basename file, path.extname file
      parts = "#{dirname}/#{basename}".split('/').slice 1

      if parts.length is 2 and package_ is parts[0] and 'index' is parts[1]
        packageIndex = file
        break

    return packageIndex

  # Render a table of package files.
  outputPackageFiles: (files, fileMap) ->

    output  = 'Filename | Title | Description\n'
    output += '-------- | ----- | -----------\n'

    files = files.sort (l, r) ->
      lp = l.split('/').length
      rp = r.split('/').length

      # First sort hierarchically.
      return -1 if lp < rp
      return 1 if lp > rp

      # Then, alphabetically.
      return -1 if l < r
      return 1 if l > r
      return 0

    for file in files
      transform = fileMap[file]
      output += "[#{
        file.split('/').slice(2).join '/'
      }](source/#{
        @linkToSource file
      }) | #{
        transform.title
      } | #{
        transform.description
      }\n"

    return output

  # Render a table of hooks for a package.
  outputPackageHooks: (files, fileMap) ->

    output = ''

    wordingFor =
      implementation: 'implements'
      invocation: 'invoke'

    for key in ['invocation', 'implementation']
      pluralKey = "#{key}s"

      # Sort the hooks list.
      hooksList = []
      for file, index in files
        transform = fileMap[file]
        for hook in transform[pluralKey]
          hooksList.push hook: hook, file: file
      hooksList = hooksList.sort (l, r) -> if l.hook < r.hook then -1 else 1

      # Output the hooks in the package.
      hookOutput = ''
      for {hook, file} in hooksList

        sourceLink = @linkToSource file

        hookOutput += """
<tr class="#{if index % 2 then 'odd' else 'even'}\">
  <td>
    <a href="../hooks##{@uniqueId 'hooks', hook}">#{hook}</a>
  </td>
  <td align="right">
    <a href="../source/#{sourceLink}##{wordingFor[key]}-hook-#{@uniqueId sourceLink, hook}">#{key}</a>
  </td>
</tr>
""".split('\n').map((e) -> "    #{e}").join('\n') + '\n'
      continue unless hookOutput

      # Output the whole hooks table.
      output += '<div class="admonition note">\n'
      output += "  <p class=\"admonition-title\">Hook #{pluralKey}"
      output += '</p>\n'
      output += '  <table>\n'

      output += hookOutput

      output += '  </table>\n'
      output += '</div>'
      output += '\n'

    return output

  # Render packages.
  transformsOutput: (transforms) ->
    self = this

    packages = @sortFilesByPackage transforms

    fileMap = @transformsFileMap transforms

    output = '\n'

    for package_, files of packages

      packageIndex = @packageIndex package_, files

      # Package name[, Title]
      output += "## `#{package_}`"
      output += " • #{
        fileMap[packageIndex].title
      }" if fileMap[packageIndex].title
      output += '\n\n'

      # [Description]
      output += "#{
        fileMap[packageIndex].description
      }\n\n" if fileMap[packageIndex].description

      output += @outputPackageFiles files, fileMap
      output += '\n'

      output += @outputPackageHooks files, fileMap
      output += '\n'

    return output

  transformForStream: (stream) -> class PackagesTransform extends Transform

    constructor: (@processor, @stream) ->
      super null

      @title = ''
      @description = ''
      @hasGottenTitleAndDescription = false

      @implementations = []
      @invocations = []

    _transform: (chunk, encoding, done) ->
      line = chunk.toString 'utf8'

      unless @hasGottenTitleAndDescription

        line = chunk.toString('utf8').trim()
        return done() if line.length is 0

        if '#'.charCodeAt(0) is line.charCodeAt(0)

          if '#'.charCodeAt(0) is line.charCodeAt(2)
            @title = line.substr 4

          else if '*'.charCodeAt(0) is line.charCodeAt(2)
            @description = line.substr 2

          else if @description?
            @description += ' ' + line.substr 2

          if '*'.charCodeAt(0) is @description.charCodeAt @description.length - 1
            @hasGottenTitleAndDescription = true

        else

          @hasGottenTitleAndDescription = true

      if matches = line.match /^\s*# #### Implements hook `([^`]+)`/
        @implementations.push matches[1]

      if matches = line.match /^\s*# #### Invoke hook `([^`]+)`/
        @invocations.push matches[1]

      done()
