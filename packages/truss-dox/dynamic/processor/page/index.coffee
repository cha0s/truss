# # Abstract documentation page
#
# *Abstract class to process a documentation page, using a template and
# generated information.*

path = require 'path'
fs = require 'fs'

Promise = require 'bluebird'

SourcesProcessor = require '../sources'

module.exports = class DoxPage extends SourcesProcessor

  constructor: (@streams, @template, @destination) ->
    super

    @idMap = {}

  process: ->
    self = this

    # Apply the transforms.
    transforms = self.streamsToTransforms()

    # Load the template and wait until streaming is done.
    new Promise (resolve, reject) =>
      fs.readFile @template, 'utf8',  (error, output) ->
        return reject error if error?

        # Append all of the transformed content.
        Promise.cast(self.transformsOutput transforms).then (tOutput) ->
          output += tOutput

          # Write it as the final page.
          fs.writeFile self.destination, output, (error) ->
            return reject error if error?
            resolve()

  transformsOutput: (transforms) ->
    output = (transform.output() for transform in transforms).join '\n'
    output += '\n'

  linkToSource: (file) ->

    link = path.dirname file
    basename = path.basename file, path.extname file
    link += "/#{basename}" if basename isnt 'index'

    return link

  uniqueId: (page, string) ->
    @idMap[page] ?= {}

    # Sanitize it.
    id = string.replace(
      /[/'']/g, ''
    ).replace(
      /\[(.*)\]\(.*\)/g, '$1'
    ).replace(
      /[^0-9A-Za-z-]+/g, '-'
    ).replace(
      /\-+/g, '-'
    ).replace(
      /^\-+|\-+$/g, ''
    ).toLowerCase()

    # Keep track of ID usage and modify the location hash for
    # subsequent uses.
    if @idMap[page][id]?
      @idMap[page][id] += 1
      id += "_#{@idMap[page][id]}"
    else
      @idMap[page][id] = 0

    return id
