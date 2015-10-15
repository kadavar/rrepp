$(document).on 'click', '.force-sync', ->
  projectId = $(this).data('project-id')
  debugger;
  action_url = "/projects/#{projectId}/force_sync"

  send_action action_url

send_action = (action_url) ->
  $.ajax
    url: action_url
