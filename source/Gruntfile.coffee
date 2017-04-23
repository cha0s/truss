# Gruntfile

*Entry point for the Grunt build process.*

```coffeescript
{fork} = require "#{__dirname}/src/bootstrap"

module.exports = (grunt) ->
```

Fork so we can bootstrap a Truss environment.

```coffeescript
  if child = fork()
    grunt.registerTask 'bootstrap', ->

      done = @async()

      child.on 'close', (code) ->

        return done() if code is 0

        grunt.fail.fatal 'Child process failed', code
```

Forward all tasks.

```coffeescript
    {tasks} = require 'grunt/lib/grunt/cli'
    grunt.registerTask tasks[0] ? 'default', ['bootstrap']
    grunt.registerTask(task, (->)) for task in tasks.slice 1

    return
```

Load configuration.

```coffeescript
  fs = require 'fs'

  yaml = require 'js-yaml'

  config = require 'config'
```

Set environment variables into config.

```coffeescript
  config.set 'path', __dirname
  config.set k, v for k, v of process.env
```

Read configuration file.

```coffeescript
  settingsFilename = config.get 'path'
  settingsFilename += '/config/settings.yml'

  throw new Error '
    Settings file not found!
    You should copy config/default.settings.yml to config/settings.yml
  ' unless fs.existsSync settingsFilename

  settings = yaml.safeLoad fs.readFileSync settingsFilename, 'utf8'
  config.set k, v for k, v of settings
```

Register the configured packages.

```coffeescript
  pkgman = require 'pkgman'
  pkgman.registerPackageList config.get 'packageList'
```

Load the packages' configuration settings and set into the default config.
#### Invoke hook [`trussConfigServer`](../../hooks#trussconfigserver)

```coffeescript
  packageConfig = new config.Config()
  for path, value of pkgman.invoke 'trussConfigServer'
    packageConfig.set path.replace(/\//g, ':'), value

  config.setDefaults packageConfig: packageConfig.toJSON()
```

# Spin up the server.

```coffeescript
```

require('main').start()

```coffeescript
```

config.load()
config.loadPackageSettings()

```coffeescript
```

## GruntConfiguration

```coffeescript
  class GruntConfiguration
```

## *constructor*

```coffeescript
    constructor: ->

      @_npmTasks = []
      @_taskConfig = {}
      @_tasks = {}

      @pkg = grunt.file.readJSON 'package.json'
```

## GruntConfiguration#configureTask

* (String) `task` - The name of the task to configure.

* (String) `key` - The name of the key in the task configuration to set.
This is generally the name of the package, but can be anything.

* (Object) `config_` - The configuration to set. See the documentation
for the particular grunt task being configured to learn how to configure
it.

*Configure a Grunt task.*

```coffeescript
    configureTask: (task, key, config_) ->

      (@_taskConfig[task] ?= {})[key] = config_

      return
```

## GruntConfiguration#taskConfiguration

* (String) `task` - The name of the task to configure.

* (String) `key` - The name of the key in the task configuration to set.
This is generally the name of the package, but can be anything.

*Get the configuration for a Grunt task.*

```coffeescript
    taskConfiguration: (task, key) -> @_taskConfig[task]?[key]
```

## GruntConfiguration#loadNpmTasks

* (String Array) `tasks` - The list of NPM tasks to load.

*Load NPM tasks.*

```coffeescript
    loadNpmTasks: (tasks) ->

      @_npmTasks.push task for task in tasks

      return
```

## GruntConfiguration#registerTask

* (String) `task` - The name of the task to configure.

* (String Array or Function) `subtasksOrFunction` - Either an array of
strings which define the dependencies for the task, or a function which
will be executed for the task.

*Register a Grunt task.*

```coffeescript
    registerTask: (task, subtasksOrFunction) ->

      if 'function' is typeof subtasksOrFunction
        @_tasks[task] = subtasksOrFunction
      else
        (@_tasks[task] ?= []).push subtasksOrFunction...

      return
```

## GruntConfiguration#copyAppFiles

* (String) `path` - The path of the files to copy.

* (String) `key` - The name of the key in the task configuration to set.
This is generally the name of the package, but can be anything.

* (String) `dest` - The destination where the files will be copied.
Defaults to `'app'`.

*Copy package files to `app`.*

```coffeescript
    copyAppFiles: (path, key, dest = 'app') ->
      dest ?= 'app'

      gruntConfig.configureTask 'copy', key, files: [
        src: '**/*'
        dest: dest
        expand: true
        cwd: path
      ]

      gruntConfig.configureTask(
        'watch', key

        files: [
          "#{path}/**/*"
        ]
        tasks: ["build:#{key}"]
      )

  gruntConfig = new GruntConfiguration()

  gruntConfig.registerTask 'production', ['build']
  gruntConfig.registerTask 'default', ['buildOnce']

  gruntConfig.registerTask 'buildOnce', do ->
    built = false

    ->
      return if built
      built = true

      grunt.task.run 'build'
```

#### Invoke hook [`trussGruntConfig`](../../hooks#trussgruntconfig)

```coffeescript
  pkgman.invoke 'trussGruntConfig', gruntConfig, grunt
```

#### Invoke hook [`trussGruntConfigAlter`](../../hooks#trussgruntconfigalter)

```coffeescript
  pkgman.invoke 'trussGruntConfigAlter', gruntConfig, grunt
```

Initialize configuration.

```coffeescript
  grunt.initConfig gruntConfig._taskConfig
```

Load NPM tasks.

```coffeescript
  npmTasksLoaded = {}
  for task in gruntConfig._npmTasks
    continue if npmTasksLoaded[task]?
    npmTasksLoaded[task] = true
    grunt.loadNpmTasks task
```

Register custom tasks.

```coffeescript
  grunt.registerTask task, actions for task, actions of gruntConfig._tasks
```
