# @module
Tower.Model.Attributes =
  ClassMethods:
    field: (name, options) ->
      @fields()[name] = new Tower.Model.Attribute(@, name, options)

    fields: ->
      @_fields   ||= {}

  get: (name) ->
    field = @constructor.fields()[name]
    
    unless @has(name)
      @attributes[name] = field.defaultValue(@) if field
    
    if field
      field.decode @attributes[name], @
    else
      @attributes[name]

  assignAttributes: (attributes) ->
    for key, value of attributes
      delete @changes[key]
      @attributes[key] = value
    @

  has: (key) ->
    @attributes.hasOwnProperty(key)

  # @example
  #   post.set $pushAll: tags: ["ruby"]
  #   post.set $pushAll: tags: ["javascript"]
  #   post.attributes["tags"] #=> ["ruby", "javascript"]
  #   post.changes["tags"]    #=> [[], ["ruby", "javascript"]]
  #   post.set $pop: tags: "ruby"
  #   post.attributes["tags"] #=> ["javascript"]
  #   post.changes["tags"]    #=> [[], ["javascript"]]
  #   if the changes looked like this:
  #     post.changes["tags"]    #=> [["ruby", "javascript"], ["javascript", "node.js"]]
  #   then the updates would be
  #     post.toUpdates()        #=> {$popAll: {tags: ["ruby"]}, $pushAll: {tags: ["node.js"]}}
  #     popAll  = _.difference(post.changes["tags"][0], post.changes["tags"][1])
  #     pushAll = _.difference(post.changes["tags"][1], post.changes["tags"][0])
  set: (key, value) ->
    @operation => Tower.oneOrMany(@, @_set, key, value)
    
  push: (key, value) ->
    @operation => Tower.oneOrMany(@, @_push, key, value)
    
  pushAll: (key, value) ->
    @operation => Tower.oneOrMany(@, @_push, key, value, true)
    
  pull: (key, value) ->
    @operation => Tower.oneOrMany(@, @_pull, key, value)
  
  pullAll: (key, value) ->
    @operation => Tower.oneOrMany(@, @_pull, key, value, true)
  
  inc: (key, value) ->
    @operation => Tower.oneOrMany(@, @_inc, key, value)
    
  addToSet: (key, value) ->
    @operation => Tower.oneOrMany(@, @_addToSet, key, value)
    
  unset: ->
    keys = _.flatten Tower.args(arguments)
    delete @attributes[key] for key in keys
    undefined

  # @private
  _set: (key, value) ->
    if Tower.Store.atomicModifiers.hasOwnProperty(key)
      @[key.replace(/^\$/, "")](value)
    else
      fields            = @constructor.fields()
      field             = fields[key]
      value             = field.encode(value, @) if field
      {before, after}   = @changes
      
      @_attributeChange(key, value)
      before[key]       = @get(key) unless before.hasOwnProperty(key)
      after.$set      ||= {}
      after.$set[key]   = value
      
      if operation = @_currentOperation
        operation.$set ||= {}
        operation.$set[key] = value
        
      #@_attributeChange(key, value)
      @attributes[key]  = value

  # @private
  _push: (key, value, array = false) ->
    fields            = @constructor.fields()
    value             = fields[key].encode(value) if key in fields
    {before, after}   = @changes
    push              = after.$push ||= {}
    
    before[key]     ||= @get(key)
    current           = @get(key) || []
    push[key]       ||= current.concat()
    
    if array == true && _.isArray(value)
      push[key] = push[key].concat(value)
    else
      push[key].push(value)
      
    if operation = @_currentOperation
      operation.$push ||= {}
      operation.$push[key] = value
    
    @attributes[key]  = push[key]
  
  # @private
  _pull: (key, value, array = false) ->
    fields            = @constructor.fields()
    value             = fields[key].encode(value) if key in fields
    {before, after}   = @changes
    pull              = after.$pull ||= {}
    
    before[key]     ||= @get(key)
    current           = @get(key) || []
    pull[key]       ||= current.concat()
    
    if array && _.isArray(value)
      pull[key].splice(pull[key].indexOf(item), 1) for item in value
    else
      pull[key].splice(pull[key].indexOf(value), 1)
      
    if operation = @_currentOperation
      operation.$pull ||= {}
      operation.$pull[key] = value
    
    @attributes[key]  = pull[key]
  
  # @private
  _inc: (key, value) ->
    fields            = @constructor.fields()
    value             = fields[key].encode(value) if key in fields
    {before, after}   = @changes
    inc               = after.$inc ||= {}
    
    before[key]       = @get(key) unless before.hasOwnProperty(key)
    inc[key]          = @get(key) || 0
    inc[key]         += value
    
    if operation      = @_currentOperation
      operation.$before ||= {}
      operation.$before[key] = @get(key) unless operation.$before.hasOwnProperty(key)
      operation.$inc    ||= {}
      operation.$inc[key] = value
      operation.$after  ||= {}
      operation.$after[key] = inc[key]
    
    @attributes[key]  = inc[key]
    
  _addToSet: (key, value) ->
    fields            = @constructor.fields()
    value             = fields[key].encode(value) if key in fields
    {before, after}   = @changes
    addToSet          = after.$addToSet ||= {}
    
    before[key]       = @get(key) unless before.hasOwnProperty(key)
    addToSet[key]   ||= (addToSet[key] || []).concat()
    addToSet[key].push value if addToSet[key].indexOf(value) == -1
    
    @attributes[key]  = addToSet[key]

module.exports = Tower.Model.Attributes
