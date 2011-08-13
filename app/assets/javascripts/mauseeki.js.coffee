# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
# 4e4632317c8f001fb300003f

window.mauseeki = {}
mauseeki = window.mauseeki
mauseeki.format_time = (time) ->
  min = parseInt time/60
  sec = time % 60
  sec = if sec < 10 then "0" + sec else sec
  min + ":" + sec

mauseeki.template =
  cache: {}
  get: (name) -> $("#tmpl_#{name}").html()
  $: (name, data = {}) ->
    @cache[name] ||= Handlebars.compile(@get name)
    $(@cache[name](data))

mauseeki.views = {}
mauseeki.models = {}

class mauseeki.models.Clip extends Backbone.Model
  toJSON: ->
    json = Backbone.Model.prototype.toJSON.call(@)
    json.time = mauseeki.format_time @get "length"
    json

class mauseeki.models.Clips extends Backbone.Collection
  model: mauseeki.models.Clip

class mauseeki.models.List extends Backbone.Model
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

        @.set(data.list)

      dataType: 'json'
      type: 'post'

  load: ->
    return if !@id

    $.ajax
      url: "/lists/#{@id}"
      data: {load: 1}
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
      success: (data) => @set data
      dataType: 'json'
      type: 'post'

class mauseeki.models.Lists extends Backbone.Collection
  model: mauseeki.models.List

class mauseeki.views.FinderView extends Backbone.View
  last_value: ""
  events:
    'keyup #find': 'look'
    'click .clear': 'clear'

  initialize: (options = {}) ->
    _.bindAll @, "reset_clips", "add_clip", "run_search", "clear"
    $(@el).html mauseeki.template.$("finder")
    @find = @$("#find").focus()
    @button = @$("button")

    @clips = new mauseeki.models.Clips
    @clips.bind "reset", @reset_clips
    @clips.bind "add", @add_clip

    @list = options.list

  look: -> 
    value = $.trim @find.val()
    return if value == @last_value
    @last_value = @find.val()
    @interval = setInterval(@run_search, 300) if !@interval

  clear: ->
    clearInterval(@interval)
    @interval = undefined
    @last_search = undefined
    @last_value = ""
    @button.removeClass("clear").removeClass("loading")
    @$("#results").empty()
    @find.val("").focus()

  run_search: ->
    query = $.trim @find.val()
    return @clear() if query == ""
    return if query == @last_search
    @last_search = query

    @loading.abort() if @loading

    @button.addClass("loading").removeClass("clear")
    console.log "running for: #{query}"
    @loading = $.ajax
      url: '/clips/results'
      data: { q: query }
      success: (data) =>
        clearInterval(@interval)
        @interval = undefined
        @button.removeClass("loading").addClass("clear")
        @loading = undefined
        @clips.reset(data)

      dataType: 'json'
      type: 'get'

  reset_clips: (clips) ->
    @$("#results").empty()
    clips.each @add_clip

  add_clip: (clip) ->
    view = new mauseeki.views.ClipView model: clip, list: @list
    @$("#results").append view.el


class mauseeki.views.PlayerView extends Backbone.View
  player: undefined
  initialize: ->
    _.bindAll @, 'playing'
    $(@el).html mauseeki.template.$("player")
    $("body").append @el

    window.onYouTubePlayerReady = (player_id) =>
      @player = document.getElementById 'ytplayer'
      @player.setVolume(100)
      setInterval @playing, 200

    oid = "W1L1cE4Qez0"
    swfobject.embedSWF("http://www.youtube.com/v/#{oid}?enablejsapi=1&playerapiid=ytplayer",
    'ytdiv', "640", "360", "9", null, {}, {allowScriptAccess: "always"}, {id: "ytplayer"})

  playing: -> @trigger "playing", @current_id()

  current_id: -> @player.getVideoUrl().match(/v=(.*)&/)[1]

  load: (id) -> 
    return @ if @current_id() == id

    @seek(0)
    @player.loadVideoById id, 0, "small"
    @

  seek: (time) -> @player.seekTo time, true; @
  play: -> @player.playVideo(); @
  pause: -> @player.pauseVideo(); @
  toggle_video: ->
    height = @$(".yt_holder").height()
    if height == 0
      @$(".yt_holder").height(400).css padding: 10
    else
      @$(".yt_holder").height(0).css padding: 0

class mauseeki.views.ClipView extends Backbone.View
  tagName: 'li'
  className: 'clip'

  events:
    'click .play': 'play'
    'click .pause': 'pause'
    'click .status': 'seek'
    'click .video': 'video'
    'click .add': 'add'
    'mousemove .status': 'show_timetip'
    'mouseout .status': 'hide_timetip'

  initialize: (options = {}) ->
    _.bindAll @, "playing"

    $(@el).html mauseeki.template.$ "clip", @model.toJSON()
    @id = @model.get("source_id")

    @player = mauseeki.player
    @player.bind "playing", @playing

    @list = options.list

  play: ->
    #TODO: make trigger
    $(".clip .pause").hide()
    $(".clip .play").show()

    @player.pause().load(@id).play()
    @$(".pause").show()
    @$(".play").hide()

  pause: ->
    @player.pause()
    @$(".pause").hide()
    @$(".play").show()

  seek: ->
    return if @player.current_id() != @id
    @player.seek @hover_time

  video: -> @player.toggle_video()

  show_timetip: (e) ->
    return if @player.current_id() != @id
    player = @player.player
    return false if !(player && player.getDuration && player.getDuration() > 0)

    $status = @$(".status")
    w = $status.width()
    x = e.pageX - $status.get(0).offsetLeft
    y = e.pageY - $status.get(0).offsetTop

    hover = parseInt( (x/w) * player.getDuration())
    return if hover <= 0
    @hover_time = hover

    td = @$(".time_display")
    top = $status.get(0).offsetTop - (td.height() * 1.5)
    td.css position: 'absolute', top: top, left: e.pageX - (td.width() / 2)
    td.html(mauseeki.format_time(hover)).show()

    false

  hide_timetip: -> @$(".time_display").hide()

  playing: (id) ->
    return if @id != id
    player = @player.player

    current_time = mauseeki.format_time Math.round player.getCurrentTime()
    length = mauseeki.format_time Math.round @model.get("length")
    @$(".time").html("#{current_time} / #{length}").show()

    w = @$('.status').width()
    playing = player.getCurrentTime() / player.getDuration()
    starting = player.getVideoStartBytes() / player.getVideoBytesTotal()
    loaded = player.getVideoBytesLoaded() / player.getVideoBytesTotal()

    sw = parseInt(w * starting)
    lw = parseInt(w * loaded)
    pw = parseInt(w * playing) - sw

    @$(".playing").css "margin-left", sw if @$(".playing").css("margin-left") != sw
    @$(".playing").width pw if @$(".playing").width() != pw

    @$(".loaded").css "margin-left", sw if @$(".loaded").css("margin-left") != sw
    @$(".loaded").width lw if @$(".loaded").width() != lw

    @pause() if playing == 1 && player.getPlayerState() == 0

  add: -> @list.add_clip(@model) if @list

class mauseeki.views.ListView extends Backbone.View
  list_id: undefined
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

  relist: ->
    name = @model.get "name"
    if name
      @$(".list-name").text(@model.get "name").show()

    if @model.get "saved"
      @$(".list-controls").hide()
      mauseeki.app.navigate "lists/#{@model.id}-#{@model.get "name"}"
    else
      @$(".list-controls").show()

  save_list: ->
    name = $.trim @$(".list-controls input").val()
    @model.save_list(name)

  add_clip: (clip) ->
    view = new mauseeki.views.ClipView model: clip
    @$(".clips").append view.el

  reset_clips: ->
    @$(".clips").empty()
    @clips.each @add_clip

class mauseeki.App extends Backbone.Router
  routes:
    "": "home"
    "lists/:id-:name": "list"

  initialize: ->
    # setup the app here
    mauseeki.player = new mauseeki.views.PlayerView

  home: ->
    list = new mauseeki.models.List
    list_view = new mauseeki.views.ListView model: list
    $("#container").append list_view.el

    finder_view = new mauseeki.views.FinderView list: list
    $("#container").append finder_view.el
    finder_view.$("#find").focus()

  list: (id, name) ->
    list = new mauseeki.models.List id: id
    list_view = new mauseeki.views.ListView model: list
    $("#container").append list_view.el

    finder_view = new mauseeki.views.FinderView list: list
    $("#container").append finder_view.el
    finder_view.$("#find").focus()
