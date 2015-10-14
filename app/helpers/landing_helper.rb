module LandingHelper
  def link_to_menu(name, url, options={})
    klass = current_page?(url) ? 'active' : ''

    content_tag(:li, (link_to name, url, options), class: klass)
  end
end
