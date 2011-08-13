mauseeki = @mauseeki

class mauseeki.views.FinderView extends Backbone.View
  last_value: ""
  events:
    'keyup #find': 'look'
    'click .clear': 'clear'

  initialize: (options = {}) ->
    _.bindAll @, "reset_clips", "add_clip", 
      "run_search", "clear", "close_results"
    $(@el).html mauseeki.template.$("finder")
    @find = @$("#find").focus()
    @button = @$("button")

    @clips = new mauseeki.models.Clips
    @clips.bind "reset", @reset_clips
    @clips.bind "add", @add_clip

    @list = options.list
    if @list
      @list.clips.bind "add", @close_results
      @list.clips.bind "reset", @close_results

  close_results: -> @clear()

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
    #console.log "running for: #{query}"
    @loading = $.ajax
      url: '/clips/results'
      data: { q: query }
      success: (data) =>
        clearInterval(@interval)
        @interval = undefined
        @button.removeClass("loading").addClass("clear")
        @loading = undefined
        @clips.reset(data)
        @$("#results").slideDown()

      dataType: 'json'
      type: 'get'

  reset_clips: (clips) ->
    @$("#results").empty()
    clips.each @add_clip

  add_clip: (clip) ->
    view = new mauseeki.views.ClipView model: clip, list: @list
    @$("#results").append view.el


