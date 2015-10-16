$(document).on 'click', '.force-sync', ->
  projectId = $(this).data('project-id')

  send_action projectId, true

$(document).on 'click', '.sync-project', ->
  projectId = $(this).data('project-id')

  send_action projectId, false

send_action = (projectId, one_time) ->
  action_url = "/projects/#{projectId}/sync_project"

  $.ajax
    url: action_url
    data: { one_time: one_time }
