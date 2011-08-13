# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
# 4e4632317c8f001fb300003f

mauseeki = @mauseeki = @mauseeki || {}

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

class mauseeki.App extends Backbone.Router
  routes:
    "": "home"
    "lists/:id-:name": "list"
    "lists/:id": "list"

  initialize: ->
    _.bindAll @, "list_added", "persist"
    # setup the app here
    mauseeki.player = new mauseeki.views.PlayerView

    @lists = new mauseeki.models.Lists
    list_ids = store.get "list_ids"
    array = []
    _.each list_ids, (id) ->
      list = new mauseeki.models.List id: id
      list.fetch(async: false)
      array.push list
    @lists.reset array

    @bind "list_added", @list_added
    @lists.bind 'change', @persist

    @lists_view = new mauseeki.views.ListsView lists: @lists
    $("#sidebar").append(@lists_view.render().el)

  persist: -> store.set "list_ids", @lists.pluck("id")

  home: ->
    $("#main").html("<h2 id='go-ahead'>Go Ahead, Make A List.</h2>")

    list = new mauseeki.models.List
    list_view = new mauseeki.views.ListView model: list
    $("#main").append list_view.el

    finder_view = new mauseeki.views.FinderView list: list
    $("#main").append finder_view.el
    finder_view.$("#find").focus()

  list: (id, name) ->
    $("#main").empty()

    list = new mauseeki.models.List id: id
    list_view = new mauseeki.views.ListView model: list
    $("#main").append list_view.el

    if @lists.get id
      finder_view = new mauseeki.views.FinderView list: list
      $("#main").append finder_view.el
      finder_view.$("#find").focus()

  list_added: (list) ->
    l = @lists.get(list.id)
    if l
      l.set(list.attributes)
    else
      @lists.add(list)
