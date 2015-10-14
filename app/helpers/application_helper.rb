module ApplicationHelper
  def bootstrap_flash
    flash_messages = []
    flash.each do |type, message|
      next if message.blank?
      type =
        case type.to_sym
        when :notice
          :success
        when :alert, :error
          :danger
        else
          type
        end

      text = content_tag(:div,
                         content_tag(:button, raw('&times;'), class: 'close', 'data-dismiss' => 'alert') +
                         message, class: "alert fade in alert-#{type}")
      flash_messages << text if message
    end
    flash_messages.join("\n").html_safe
  end
end
