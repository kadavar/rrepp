$(document).on 'click', '.force-sync', ->
  projectId = $(this).data('project-id')

  $('#force-form').attr('action', "/projects/#{projectId}/force_sync")

  $('input[type="submit"]').addClass('disabled')

  $('#modal').modal('show')

$(document).on 'click', '#cancel-modal', ->
  $('#modal').modal('hide')

  $("#force-form")[0].reset()

$(document).on 'click', '#modal', ->
  $('#force-form').validator('validate')

$(document).ready ->
  $('#force-form').validator().on 'submit', (e) ->
    unless e.isDefaultPrevented()
      $('#modal').modal('hide')

      $("#force-form")[0].reset()
