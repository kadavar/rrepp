$(document).on 'click', '.force-sync', ->
  projectId = $(this).data('project-id')
  $('input[name="id"]').val(projectId)

  $('#modal').modal('show')
