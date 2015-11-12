refreshStatuses = ->
  $.ajax
    url: 'projects/status'

$(document).ready ->
  if  $('div.projects-index').length
    setInterval refreshStatuses, 2000
