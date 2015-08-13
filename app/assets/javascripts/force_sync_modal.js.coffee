$(document).on 'click', '.force-sync', ->
  projectId = $(this).data('project-id')
  $('input[name="id"]').val(projectId)

  $('#modal').modal('show')

$(document).on 'click', '#force-button', ->
  projectId = $('input[name="id"]').val()
  jiraPassword = $('input[name="jira_password"]').val()
  pivotalToken = $('input[name="pivotal_token"]').val()

  forceSync projectId, jiraPassword, pivotalToken

forceSync = (projectId, jiraPassword, pivotalToken) ->
  $.ajax
    type: 'GET'
    url: "/projects/#{projectId}/force_sync"
    data: jira_password: jiraPassword, pivotal_token: pivotalToken
