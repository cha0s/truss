# # Grunt build process - Documentation
#
# *Build the documentation in `gh-pages`.*
{fork, spawn} = require 'child_process'

exports.pkgmanRegister = (registrar) ->

  # #### Implements hook `trussGruntConfig`.
  registrar.registerHook 'trussGruntConfig', (gruntConfig, grunt) ->

    gruntConfig.configureTask 'clean', 'truss-dox', [
      'mkdocs.yml'
      'docs/source'
      'docs/{hooks,packages,todos}.md'
      'gh-pages/*'
      '!gh-pages/.git'
      '!gh-pages/.gitignore'
    ]

    gruntConfig.registerTask 'truss-dox:prepareDirectory', ->
      grunt.file.mkdir 'gh-pages'

    gruntConfig.registerTask 'truss-dox:dynamic', ->
      done = @async()

      fork("#{__dirname}/dynamic.coffee").on 'close', (code) ->
        return done() if code is 0

        grunt.fail.fatal 'Dynamic documentation generation failed', code

    gruntConfig.registerTask 'truss-dox:mkdocs', ->
      done = @async()

      spawn('mkdocs', ['build']).on 'close', (code) ->
        return done() if code is 0

        grunt.fail.fatal 'Running `mkdocs build` failed', code

    gruntConfig.registerTask 'truss-dox', [
       'truss-dox:prepareDirectory'
       'truss-dox:dynamic'
       'truss-dox:mkdocs'
    ]