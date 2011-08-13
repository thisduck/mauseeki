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
  last_value: ""
  events:
    'keyup #find': 'look'
    'click .clear': 'clear'

  initialize: ->
    _.bindAll @, "reset_clips", "add_clip", "run_search", "clear"
    $(@el).html mauseeki.template.$("finder")
    @find = @$("#find").focus()
    @button = @$("button")

    @clips = new mauseeki.models.Clips
    @clips.bind "reset", @reset_clips
    @clips.bind "add", @add_clip

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
    'click .status': 'seek'
    'mousemove .status': 'show_timetip'
    'mouseout .status': 'hide_timetip'

  initialize: -> 
    _.bindAll @, "playing"

    $(@el).html mauseeki.template.$ "clip", @model.toJSON()
    @id = @model.get("source_id")

    @player = mauseeki.player
    @player.bind "playing", @playing

  play: ->
    #TODO: make trigger
    $(".clip .pause").hide()
    $(".clip .play").show()

    @player.pause().load(@id).play()
    @$(".pause").show()
    @$(".play").hide()
    false

  pause: ->
    @player.pause()
    @$(".pause").hide()
    @$(".play").show()
    false

  seek: ->
    return if @player.current_id() != @id
    @player.seek @hover_time
    false

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

