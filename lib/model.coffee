_ = require('underscore')
crypto = require('crypto')
{AttributeError} = require('./errors')

module.exports = class Model
  @attributes: (attributes...) -> @_attributes = attributes

  constructor: (args) ->
    for k,v of args
      @[k] = v
      @_attributeError(k) unless k in @constructor._attributes

  _createId: ->
    crypto.randomBytes(20).toString('hex')

  _attributeError: (attribute) ->
    throw new AttributeError("Invalid field #{attribute}")

  _isUrl: (url) ->
    regexp = /(ftp|http|https):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/
    regexp.test(url)

  _validateNotNull: (field) ->
    @_attributeError(field) unless @[field]?

  _validateBoolean: (field) ->
    @_attributeError(field) if @[field] and @[field] not in [true, false]
