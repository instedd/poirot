# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  if window.controller == 'pages' and window.action == 'index'
    $.getJSON('/activities').then (data) ->
      for i in [0...data.items.length]
        item = data.items[i]
        item.start = new Date(new Number(item.start))
        item.end = new Date(new Number(item.end))
      renderSwimlanes(data)

