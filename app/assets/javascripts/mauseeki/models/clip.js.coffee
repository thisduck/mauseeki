mauseeki = @mauseeki

class mauseeki.models.Clip extends Backbone.Model
  toJSON: ->
    json = Backbone.Model.prototype.toJSON.call(@)
    json.time = mauseeki.format_time @get "length"
    json

class mauseeki.models.Clips extends Backbone.Collection
  model: mauseeki.models.Clip

