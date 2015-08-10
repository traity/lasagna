_            = require('underscore')
Promise      = require('bluebird')
express      = require('express')
bearerToken  = require('express-bearer-token')
bodyParser   = require('body-parser')
multiparty   = require('connect-multiparty')
domain       = require('domain')
async        = require('async')
{OAuthError} = require('lasagna')

module.exports = class App
  constructor: (port, api, factory, middlewares...) ->
    @_port        = port
    @_factory     = factory
    @_middlewares = middlewares
    @_init(api)

  start: ->
    @_app.listen(@_port)

  _init: (api) ->
    @_app = express()
    @_app.use(bodyParser.json())
    @_app.use(bodyParser.urlencoded(extended: true))
    @_app.use(bearerToken())
    @_app.use(multiparty())
    @_app.use (err, req, res, next) => @_onError(err, res)
    for [method, path, service, action, metadata] in api
      do (service, action, metadata) =>
        @_app[method] path, (req, res) =>
          @_addMetadata(req, service, action, metadata)
          @_safeApiCall(@_factory[service], action, metadata, req, res)

  _addMetadata: (req, service, action, metadata) ->
    req.metadata = metadata || {}
    req.metadata.service = service
    req.metadata.action = action

  _safeApiCall: (service, action, metadata, req, res) ->
    d = domain.create()
    d.on('error', (err) => @_onError(err, res))
    d.add(res)
    d.run => process.nextTick =>
      @_callMiddlewares req, res, metadata, (err) =>
        return @_onError(err, res) if err?
        @_apiCall(service, action, req, res)

  _apiCall: (service, action, req, res) ->
    params = _.defaults(req.files || {}, req.params, req.query, req.body)
    result = service[action].call(service, params)
    Promise.resolve(result)
    .then (output) => @_onOutput(output, res)
    .catch (err) => @_onError(err, res)

  _callMiddlewares: (req, res, metadata, next) ->
    actions = for middleware in @_middlewares
      do (middleware) ->
        (cb) ->
          middleware(req, res, cb)
    async.series(actions, next)

  _onError: (err, res) ->
    console.error err.stack
    res.status(err.status || 500).json(error: _.pick(err, 'name', 'message'))

  _onOutput: (output, res) ->
    if output?._redirect?
      res.redirect(output._redirect)
    else
      res.json(output || {})
