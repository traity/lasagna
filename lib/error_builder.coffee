module.exports = (errors) ->
  output = {}
  for name, status of errors
    do (name, status) ->
      error = class extends Error
        constructor: (@message) ->
          @name = name
          @status = status
          Error.captureStackTrace(this, name)
      output[name] = error
  output
