mauseeki = @mauseeki

class mauseeki.views.ClipView extends Backbone.View
  tagName: 'li'
  className: 'clip'

  events:
    'click .play': 'play'
    'click .pause': 'pause'
    'click .status': 'seek'
    'click .video': 'video'
    'click .add': 'add'
    'click .delete': 'delete'
    'mousemove .status': 'show_timetip'
    'mouseout .status': 'hide_timetip'

  initialize: (options = {}) ->
    _.bindAll @, "playing", "render", "remove_clip", "next", "play"
    @player = mauseeki.player
    @player.bind "playing", @playing

    @list = options.list
    if @list
      @list.clips.bind "remove", @remove_clip
    @render()

  render: ->
    if @model
      $(@el).html mauseeki.template.$ "clip", @model.toJSON()
      $(@el).attr "data-id", @model.id
      @id = @model.get("source_id")
      if @list
        in_memory = mauseeki.app.lists.get(@list.id) || @list.get "mine"
        @$(".edit").remove() if !in_memory

      @model.bind "play", @play
    @

  play: ->
    mauseeki.trigger "clip:play", @
    #TODO: make trigger
    $(".clip .pause").hide()
    $(".clip .play").show()

    @auto_pause = false
    @player.pause().load(@id).play()
    @$(".pause").show()
    @$(".play").hide()

  pause: ->
    @player.pause()
    @$(".pause").hide()
    @$(".play").show()

  seek: ->
    return if @player.current_id() != @id
    @auto_pause = false
    @player.seek @hover_time

  video: -> @player.toggle_video()

  show_timetip: (e) ->
    return if @player.current_id() != @id
    player = @player.player
    return false if !(player && player.getDuration && player.getDuration() > 0)

    $status = @$(".status")
    w = $status.width()
    x = e.pageX - $status.offset().left
    y = e.pageY - $status.offset().top

    hover = parseInt( (x/w) * player.getDuration())
    return if hover <= 0
    @hover_time = hover

    td = @$(".time_display")
    top = $status.position().top - (td.height() * 1.5)
    td.css position: 'absolute', top: top, left: x - (td.width() / 2)
    td.html(mauseeki.format_time(hover)).show()

    false

  hide_timetip: -> @$(".time_display").hide()

  playing: (id) ->
    return if @id != id
    player = @player.player

    state = player.getPlayerState()
    if @$(".play:visible") && state == 1
      @$(".pause").show()
      @$(".play").hide()
    else if state == 0 || state == 2
      @$(".pause").hide()
      @$(".play").show()

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

    if playing == 1 && player.getPlayerState() == 0 && !@auto_pause
      @auto_pause = true
      @pause()
      @next()

  add: -> @list.add_clip(@model) if @list
  delete: -> @list.remove_clip(@model) if @list
  remove_clip: (clip) ->
    return if clip.id != @model.id
    $(@el).fadeOut => @remove()

  next: ->
    return if !@list
    index = @list.clips.indexOf(@model)
    clip = @list.clips.at(index + 1)
    clip.trigger("play") if clip
