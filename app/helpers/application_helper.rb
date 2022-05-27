module ApplicationHelper

  def markdown(text, escape_html: true)
    return '' if text.blank?

    markdown_options = {
      autolink:            true,
      space_after_headers: true,
      no_intra_emphasis:   true,
      fenced_code_blocks:  true,
      strikethrough:       true,
      superscript:         true,
      underline:           true,
      highlight:           true,
      quote:               true
    }
    render_options = {
      filter_html: false,
      no_images:   false,
      no_styles:   true
    }
    render_options[:escape_html] = true if escape_html

    # Redcarpet doesn't remove HTML comments even with `filter_html: true`
    # https://github.com/vmg/redcarpet/issues/692
    uncommented_text = text.gsub(/<!--(.*?)-->/, '')

    markdown = Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(render_options),
      markdown_options
    )
    markdown.render(uncommented_text).html_safe
  end

  def offset_step_path(offset=0, origin_path=request.path)
    Rails.configuration.menu_entries.each_with_index do |menu_entry, index|
      if Rails.application.routes.recognize_path(menu_entry[:target]) == Rails.application.routes.recognize_path(origin_path)
        begin
          return Rails.configuration.menu_entries[index + offset][:target]
        rescue
          return nil
        end
      end
    end
    return nil
  end

  def next_step_path(origin_path=request.path)
    offset_step_path(1, origin_path)
  end

  def previous_step_path(origin_path=request.path)
    offset_step_path(-1, origin_path)
  end

  def next_step_button(origin_path=request.path)
    if path = next_step_path(origin_path)
      link_to(t('actions.next'), path, class: "btn btn-primary")
    end
  end

  def previous_step_button(origin_path=request.path)
    if path = previous_step_path(origin_path)
      link_to(t('actions.previous'), path, class: "btn btn-secondary")
    end
  end

  def cancel_deploy_button()
    img_tag = content_tag(:i, 'cancel', class: 'eos-icons')
    span_tag = content_tag(:span, t('cancel_deployment'))
    tags = [img_tag, span_tag]

    style = "color: red; border-color:red; float: left"
    link_to(wrapup_path(cancel: true), class: "btn btn-secondary", style: style) do
      tags.map do |item|
        concat(item)
      end
    end
  end

  def page_header(title)
    render('layouts/page_header', title: title)
  end

  def alerts
    flash.collect do |context, message|
      # Skip empty messages
      next if message.blank?
      message_sections = message.split("\n")
      title = message_sections[0]
      body = if message_sections.length > 1
        message_sections[1..].join("\n")
      else
        ''
      end

      render "layouts/alerts/#{context}", title: title, body: body
    end.join.html_safe
  end
end
