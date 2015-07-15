_ = require('underscore')
Promise = require('bluebird')
assert = require('assert')
{NotFoundError} = require('./errors')

module.exports =
  behavesLikeARepository: (buildItem) ->
    describe 'repository', ->
      beforeEach ->
        @repository.clear()
        .then =>
          @repository.put(buildItem())
        .then (item) =>
          @item = item

      it 'stores an item', ->
        @repository.count().then (count) ->
          assert.equal(count, 1)

      it 'updates an item', ->
        @repository.put buildItem()
        .then =>
          @repository.count()
        .then (count) =>
          assert.equal(count, 1)

      it 'finds an existing item', ->
        @repository.findOneById(buildItem().id).then (item) =>
          assert(_.isEqual(item, @item))

      it 'deletes an item', ->
        @repository.delete(buildItem().id).then =>
          @repository.findOneById buildItem().id
        .then -> throw new Error('An error should have been thrown')
        .catch (err) -> assert(err instanceof NotFoundError)

      it 'throws an error when finding a non-existing item', ->
        @repository.findOneById "#{buildItem().id}-something-else"
        .then -> throw new Error('An error should have been thrown')
        .catch (err) -> assert(err instanceof NotFoundError)

  behavesLikeATimestampedRepository: (buildItem) ->
    describe 'timestamped repository', ->
      beforeEach ->
        @repository.clear()
        .then =>
          @storeDate = new Date
          @repository.put(buildItem(createdAt: null, updatedAt: null))
        .then (item) =>
          @item = item

      it 'timestamps when storing an item', ->
        @repository.findOneById(buildItem().id).then (item) =>
          assert.equal(item.createdAt - item.updatedAt, 0)
          assert(@storeDate - item.updatedAt < 100)

      it 'timestamps when updating an item', ->
        Promise.delay(10).then =>
          updateDate = new Date
          @repository.put(@item)
          .then =>
            @repository.findOneById(buildItem().id)
          .then (item) =>
            assert(item.createdAt - item.updatedAt != 0)
            assert(updateDate - item.updatedAt < 100)
