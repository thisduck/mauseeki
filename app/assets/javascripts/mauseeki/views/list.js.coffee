mauseeki = @mauseeki

class mauseeki.views.ListView extends Backbone.View
  events:
    "click .save-list": "save_list"

  initialize: -> 
    _.bindAll @, 'add_clip', 'reset_clips', 'relist'

    $(@el).html mauseeki.template.$ "list", @model.toJSON()
    if !@model.get("name")
      @$(".list-name").hide()
      @$(".list-controls").hide()

    @model.bind "change", @relist

    @clips = @model.clips
    @clips.bind 'add', this.add_clip
    @clips.bind 'reset', this.reset_clips

    @model.load()

    @$(".clips").sortable
      handle: ".move"
      update: =>
        ids = _.map @$(".clips .clip"), (clip) -> $(clip).attr("data-id")
        $.ajax
          type: 'post'
          url: "/lists/#{@model.id}/order"
          data: list: order: ids


  relist: ->
    in_memory = mauseeki.app.lists.get(@model.id) || @model.get "mine"
    name = @model.get "name"
    if name
      @$(".list-name").text(@model.get "name").show()

    @$(".list-controls").hide()
    if @model.get "saved"
      mauseeki.app.navigate "lists/#{@model.id}"
    else
      @$(".list-controls").show() if in_memory

  save_list: ->
    name = $.trim @$(".list-controls input").val()
    @model.save_list(name)

  add_clip: (clip) ->
    view = new mauseeki.views.ClipView model: clip, list: @model
    @$(".clips").append view.el

  reset_clips: ->
    @$(".clips").empty()
    @clips.each @add_clip

class mauseeki.views.ListsView extends Backbone.View
  className: 'lists-view'
  initialize: (options = {}) ->
    _.bindAll @, 'render', 'add_list'

    @lists = options.lists
    @lists.bind 'add', @render
    @lists.bind 'change', @render

  render: ->
    $(@el).html mauseeki.template.$("lists")
    @ul = @$("#lists")
    @lists.each @add_list
    @

  add_list: (list) ->
    json = list.toJSON()
    template = "<li><a class='app-link' href='/lists/#{list.id}'>#{list.get "name"}</a></li>"
    @ul.append template

