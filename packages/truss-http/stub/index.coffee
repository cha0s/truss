# # HTTP server stub
#
# *A barebones HTTP server.*

exports.pkgmanRegister = (registrar) ->

  registrar.recur [
    'router'
  ]
