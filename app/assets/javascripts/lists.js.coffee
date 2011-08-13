# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

window.mauseeki = {}
mauseeki = window.mauseeki
mauseeki.format_time = (time) ->
  min = parseInt time/60
  sec = time % 60
  sec = if sec < 10 then "0" + sec else sec
  min + ":" + sec

mauseeki.views = {}
mauseeki.models = {}

class mauseeki.models.Clip extends Backbone.Model
  toJSON: ->
    json = Backbone.Model.prototype.toJSON.call(@)
    json.time = mauseeki.format_time @get "length"
    json

class mauseeki.models.Clips extends Backbone.Collection
  model: mauseeki.models.Clip

mauseeki.template =
  cache: {}
  get: (name) -> $("#tmpl_#{name}").html()
  $: (name, data = {}) ->
    @cache[name] ||= Handlebars.compile(@get name)
    $(@cache[name](data))

class mauseeki.views.FinderView extends Backbone.View
  events: {}
  initialize: ->
    _.bindAll @, "reset_clips", "add_clip"
    $(@el).html mauseeki.template.$("finder")
    @find = @$("#find")

    @clips = new mauseeki.models.Clips
    @clips.bind "reset", @reset_clips
    @clips.bind "add", @add_clip

    @find.autocomplete(
      source: "/clips/livesuggest"
      select: (e, ui) =>
        @run_search() #if 13 != (e.keyCode || e.which)

      open: (e, ui) =>
#        @hide_autocomplete() if @live_string == @results_string

#     ).keypress( (e) =>
#       @live_string = @find.val()
#       if 13 == (e.keyCode || e.which)
#         @hide_autocomplete()
#         @run_search()
# 
    ).focus()

  run_search: ->
    query = @find.val()
    $.ajax
      url: '/clips/search'
      data: { query: query }
      success: (data) =>
        @clips.reset(data)
        @hide_autocomplete()
        @results_string = query
        #console.log(@clips_view.clips.length)

      dataType: 'json'
      type: 'get'

  hide_autocomplete: -> @find.autocomplete('widget').hide()
  reset_clips: (clips) ->
    @$("#results").empty()
    clips.each @add_clip

  add_clip: (clip) ->
    view = new mauseeki.views.ClipView model: clip
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
      setInterval @playing, 10

    oid = "W1L1cE4Qez0"
    swfobject.embedSWF("http://www.youtube.com/v/#{oid}?enablejsapi=1&playerapiid=ytplayer",
    'ytdiv', "640", "360", "9", null, {}, {allowScriptAccess: "always"}, {id: "ytplayer"})

  playing: -> @trigger "playing", @current_id()

  current_id: -> @player.getVideoUrl().match(/v=(.*)&/)[1]

  load: (id) -> 
    return @ if @current_id() == id
    @player.loadVideoById id, 0, "small"
    @

  seek: (time) -> @player.seekTo time, true; @
  play: -> @player.playVideo(); @
  pause: -> @player.pauseVideo(); @

class mauseeki.views.ClipView extends Backbone.View
  tagName: 'li'
  className: 'clip'

  events:
    'click .play': 'play'
    'click .pause': 'pause'

  initialize: -> 
    _.bindAll @, "playing"

    $(@el).html mauseeki.template.$ "clip", @model.toJSON()
    @id = @model.get("source_id")

    @player = mauseeki.player
    @player.bind "playing", @playing

  play: ->
    @player.load(@id).play()
    @$(".pause").show()
    @$(".play").hide()
    false

  pause: ->
    @player.pause()
    @$(".pause").hide()
    @$(".play").show()
    false

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

