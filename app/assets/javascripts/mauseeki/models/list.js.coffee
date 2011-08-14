mauseeki = @mauseeki

class mauseeki.models.List extends Backbone.Model
  urlRoot: '/lists'
  default_name: "name this list..."
  initialize: ->
    @clips = new mauseeki.models.Clips

  toJSON: ->
    json = Backbone.Model.prototype.toJSON.call(@)
    json.name = @default_name if !json.name or json.name.match /^unnamed/
    json

  add_clip: (clip) ->
    $.ajax
      url: '/lists/add_clip'
      data:
        list_id: @id || ""
        clip: clip.toJSON()

      success: (data) =>
        clip = @clips.get(data.clip.id)
        if !clip
          @clips.add(data.clip)
        else
          clip.set(data.clip)

        data.list.mine = true
        @.set(data.list)
        mauseeki.app.trigger "list_added", @

      dataType: 'json'
      type: 'post'

  remove_clip: (clip) ->
    $.ajax
      url: "/lists/#{@id}/remove_clip"
      data: clip_id: clip.id
      success: (data) =>
        c = @clips.get(clip.id)
        @clips.remove(clip) if c
      dataType: 'json'
      type: 'post'

  load: (sync) ->
    return if !@id

    $.ajax
      url: "/lists/#{@id}"
      data: {load: 1}
      async: !sync,
      success: (data) =>
        @set data.list
        @clips.reset data.clips
      dataType: 'json'
      type: 'get'

  save_list: (name) ->
    return if !@id

    return if name == @default_name
    $.ajax
      url: '/lists/' + @id + '/save',
      data:
        list: {name: name}
      success: (data) => 
        data.mine = true
        @set data
        mauseeki.app.trigger "list_added", @
      dataType: 'json'
      type: 'post'

class mauseeki.models.Lists extends Backbone.Collection
  url: '/lists'
  model: mauseeki.models.List

