# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

window.mauseeki = {}
mauseeki = window.mauseeki
# mauseeki.format_time = function(time) {
#   var min = parseInt(time / 60);
#   var sec = time % 60;
#   sec = (sec < 10) ? "0" + sec : sec;
#   return min + ":" + sec;
# };

mauseeki.views = {}
mauseeki.models = {}
class mauseeki.views.FinderView extends Backbone.View
  events: {
  }
  initialize: ->
    $(@el).html $("#tmpl_finder").html()
    @find = @$("#find")

    #this.clips_view = new mauseeki.views.ClipListView({el : this.$(".finder-list")});
    #this.clips_view.set_finder(this);

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
        #@clips_view.clips.refresh(data)
        @hide_autocomplete()
        @results_string = query
        #console.log(@clips_view.clips.length)

      dataType: 'json'
      type: 'get'

  hide_autocomplete: -> @find.autocomplete('widget').hide()
