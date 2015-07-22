module.exports = class Action
  @action: (constructorArgs...) ->
    (args...) =>
      action = new @(constructorArgs...)
      action.run.bind(action)(args...)
