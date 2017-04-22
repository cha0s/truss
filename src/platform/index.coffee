
platform = {}

exports.set = (type) ->

  Platform = require "platform/#{type}"
  platform = new Platform()

exports.get = -> platform
