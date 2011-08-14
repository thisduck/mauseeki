mauseeki = @mauseeki

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

  current_id: -> @player?.getVideoUrl().match(/v=(.*)&/)[1]

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

