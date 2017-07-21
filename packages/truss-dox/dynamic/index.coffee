# # Dynamic documentation
#
# *Generate all of the dynamic aspects of the project documentation.*

fs = require 'fs'

_ = require 'lodash'
glob = require 'glob'
Promise = require 'bluebird'

{LineStream} = require 'byline'

pkgman = require 'pkgman'

promiseForStream = (stream) ->
  new Promise (resolve, reject) ->
    stream.on 'error', reject
    stream.on 'close', resolve

# Gather all source files.
sourceFilesPromise = new Promise (resolve, reject) ->

  # #### Invoke hook `trussDoxSources`.
  sourceFiles = _.flatten pkgman.invokeFlat 'trussDoxSourceList'
  glob "{#{sourceFiles.join ','}}", (error, files) ->
    return reject error if error?
    resolve files

# Map source files to streams.
sourceStreamsPromise = sourceFilesPromise.then (files) ->
  for file in files
    lineStream = new LineStream keepEmptyLines: true
    lineStream.file = file

    lineStream.promise = promiseForStream fstream = fs.createReadStream file
    fstream.pipe lineStream

    lineStream

processorsPromise = sourceStreamsPromise.then (streams) ->

  # ###### TODO: This should be dynamic/hook-based
  SourcesToMarkdown = require './processor/sources/to-markdown'

  DoxPageTodos = require './processor/page/todos'
  DoxPageHooks = require './processor/page/hooks'
  DoxPagePackages = require './processor/page/packages'
  DoxPageMkdocs = require './processor/page/mkdocs'

  docs = 'packages/truss-dox/docs'

  processors = [
    new SourcesToMarkdown streams

    new DoxPageTodos(
      streams, "#{docs}/todos.template.md", "#{docs}/todos.md"
    )
    new DoxPageHooks(
      streams, "#{docs}/hooks.template.md", "#{docs}/hooks.md"
    )
    new DoxPagePackages(
      streams, "#{docs}/packages.template.md", "#{docs}/packages.md"
    )
    new DoxPageMkdocs(
      streams, "#{docs}/mkdocs.template.yml", 'mkdocs.yml'
    )
  ]

  Promise.all(processor.process() for processor in processors)

exports.promise = processorsPromise
