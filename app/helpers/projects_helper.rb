module ProjectsHelper
  def project_label(status)
    if status
      content_tag(:span, 'Running', class: 'label label-success')
    else
      content_tag(:span, 'Stopped', class: 'label label-danger')
    end
  end
end
