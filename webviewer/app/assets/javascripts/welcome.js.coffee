# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$(document).ready ->
  host = location.host.split(':')[0]
  localurl = 'ws://' + host + ':9876'
  zoomurl = 'ws://zoom.gina.alaska.edu:9876'

  initWebsockets('Local', 'local', localurl, true)
  initWebsockets('Zoom', 'zoom', zoomurl, false)

  $(document).on('click', '#feeds ul.nav-tabs a', (e) ->
    e.preventDefault();
    $(this).tab('show');
    $(this).data('unread', 0)
    updateUnreadBadge($(this).attr('href').replace('#', ''))
  )

updateUnreadBadge = (target, unread = null) ->
  badge = $("#feeds ul.nav-tabs a[href=\"##{target}\"] .badge")

  if unread == null
    unread = getTab(target).data('unread')

  if badge.length == 0
    getTab(target).append(" <span class=\"badge\">#{unread}</span>")
  else
    badge.text(unread)

createTab = (name, target, url, active = false) ->
  $('#feeds ul.nav-tabs').append("<li><a href=\"##{target}\">#{name}</a>")
  $('#feeds div.tab-content').append("<div id=\"#{target}\" class=\"tab-pane\"></div>")
  $("#feeds ul.nav-tabs a[href=\"##{target}\"]").data('unread', 0)
  
  if active
    $("#feeds ul.nav-tabs a[href=\"##{target}\"]").tab('show')
    updateUnreadBadge(target, 0)
  else
    updateUnreadBadge(target)  


getTab = (target) ->
  $("#feeds ul.nav-tabs a[href=\"##{target}\"]")

initWebsockets = (name, target, url, active=false) ->
  createTab(name, target, url, active)

  ws = new WebSocket(url)
  ws.unread = 0
  ws.onmessage = (evt) ->
    if !getTab(target).parent().hasClass('active')
      unread = getTab(target).data('unread') + 1
      getTab(target).data('unread', unread)
     
    updateUnreadBadge(target)
    $("##{target}").prepend("<pre>"+evt.data+"</pre>")
  ws.onclose = ->
    $("##{target}").prepend("<pre>Socket Closed</pre>")
  ws.onopen = ->
    $("##{target}").prepend("<pre>Socked Opened</pre>")