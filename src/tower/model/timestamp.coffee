Tower.Model.Timestamp =
  ClassMethods:
    timestamps: ->
      @include Tower.Model.Timestamp.CreatedAt
      @include Tower.Model.Timestamp.UpdatedAt

      @field "createdAt", type: "Date"
      @field "updatedAt", type: "Date"

      @before "create", "setCreatedAt"
      @before "save", "setUpdatedAt"

  CreatedAt:
    ClassMethods: {}

    setCreatedAt: ->
      @set "createdAt", new Date

  UpdatedAt:
    ClassMethods: {}

    setUpdatedAt: ->
      @set "updatedAt", new Date

module.exports = Tower.Model.Timestamp
