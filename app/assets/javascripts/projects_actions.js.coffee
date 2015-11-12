$(document).on 'click', '.force-sync', ->
  projectId = $(this).data('project-id')

  sync_project projectId, true

$(document).on 'click', '.project-active', ->
  update_project this.value, this.checked

sync_project = (projectId, one_time) ->
  action_url = "/projects/#{projectId}/sync_project"

  $.ajax
    url: action_url

update_project = (projectId, active) ->
  action_url = "/projects/" + projectId

  $.ajax
    url: action_url,
    data: { project: { active: active } },
    method: 'PUT'
