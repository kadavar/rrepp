module ProjectsHelper
  def project_label(status)
    content_tag(:span, "#{status}", class: 'label label-success')
  end
end
