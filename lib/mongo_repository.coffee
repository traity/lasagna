_ = require('underscore')
crypto = require('crypto')
{NotFoundError} = require('./errors')

module.exports = class MongoRepository
  @model: (model) -> @_model = model
  @timestamps: (timestamps) -> @_timestamps = timestamps

  constructor: (items) ->
    @_items      = items
    @_model      = @constructor._model
    @_timestamps = @constructor._timestamps

  findOneById: (id) ->
    @_findOneBy _id: id

  put: (item) ->
    item = @_serialize(item)
    @_items.update({_id: item._id}, item, {upsert: true}).then =>
      @_deserialize(item)

  count: ->
    @_items.find().count()

  delete: (id) ->
    @_deleteAllBy(_id: id)

  clear: ->
    @_deleteAllBy({})

  _findOneBy: (args) ->
    @_findAllBy(args).then (items) =>
      throw new NotFoundError("#{@_model.name} not found") if !items[0]?
      items[0]

  _findAllBy: (args) ->
    @_items.find(args).toArray().then (items) => @_buildItems(items)

  _deleteAllBy: (args) ->
    @_items.remove(args)

  _buildItems: (items) ->
    for item in items
      @_deserialize(item)

  _deserialize: (item) ->
    newItem = _(item).clone()
    newItem.id = newItem._id
    delete newItem._id
    new @_model(newItem)

  _serialize: (item) ->
    newItem = {}
    newItem[k] = v for own k,v of item when k in item.constructor._attributes
    new @_model(newItem)
    newItem._id = newItem.id || crypto.randomBytes(20).toString('hex')
    if @_timestamps
      now = new Date
      newItem.updatedAt = now
      newItem.createdAt ||= now
    delete newItem.id
    newItem