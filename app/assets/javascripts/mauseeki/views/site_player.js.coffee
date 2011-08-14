mauseeki = @mauseeki

class mauseeki.views.SitePlayerView extends mauseeki.views.ClipView
  tagName: "div"

  initialize: (options = {}) ->
    mauseeki.views.ClipView.prototype.initialize.call(@, options)
    _.bindAll @, "set_clip"
    mauseeki.bind "clip:play", @set_clip

  set_clip: (view) ->
    return if @model?.id == view.model.id
    @model = view.model
    @render()
    @model.unbind "play", @play
    @$(".video").show()
