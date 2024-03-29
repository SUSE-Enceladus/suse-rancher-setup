module ApplicationHelper

  def markdown(text, escape_html: true)
    return '' if text.blank?

    markdown_options = {
      autolink:                      true,
      space_after_headers:           true,
      no_intra_emphasis:             true,
      fenced_code_blocks:            true,
      disabled_indented_code_blocks: true,
      strikethrough:                 true,
      superscript:                   true,
      underline:                     true,
      highlight:                     true,
      quote:                         true
    }
    render_options = {
      filter_html: true,
      no_images:   false,
      no_styles:   true,
      hard_wrap:   true
    }
    render_options[:escape_html] = true if escape_html

    # Redcarpet doesn't remove HTML comments even with `filter_html: true`
    # https://github.com/vmg/redcarpet/issues/692
    uncommented_text = text.gsub(/<!--(.*?)-->/, '')

    markdown = Redcarpet::Markdown.new(
      LassoRender.new(render_options),
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
    style = if @deploy_failed then "float: left" else "" end
    if path = next_step_path(origin_path)
      link_to(t('actions.next'), path, class: "btn btn-primary", style: style)
    end
  end

  def previous_step_button(origin_path=request.path)
    disabled = if (@refresh_timer || @deploy_failed) then "disabled" else "" end
    if path = previous_step_path(origin_path)
      link_to(t('actions.previous'), path, class: "btn btn-secondary #{disabled}")
    end
  end

  def page_header(title)
    render('layouts/page_header', title: title)
  end

  def alerts
    flash.collect do |context, message|
      # Skip empty messages
      next if message.blank?
      message_sections = message.to_s.split("\n")
      title = message_sections[0]
      body = if message_sections.length > 1
        message_sections[1..].join("\n")
      else
        ''
      end

      render "layouts/alerts/#{context}", title: title, body: body
    end.join.html_safe
  end

  def friendly_type(type)
    type = type.split("::")
    resource_name = type[1].underscore.humanize
    resource_name = resource_name.titleize if resource_name.include? ' '
    type = type[0]
    "#{type} #{resource_name}"
  end

  def access_menu?(target)
    login_access = ((target != '/' && valid_login?) || (target == '/' && !valid_login?))
    access_and_not_done = (can(target) && !setup_done?)
    deployment_failed = (target.include?('wrapup') && @deploy_failed)
    return (access_and_not_done || deployment_failed) && !@refresh_timer && login_access
  end

  def selected_class(target)
    active_link_to_class(target, class_active: 'selected', active: :exclusive)
  end

  def disabled_class(target)
    'disabled' unless access_menu?(target)
  end

  def csp_key()
    return 'aws' if defined?(AWS::Engine)
    return 'azure' if defined?(Azure::Engine)
  end

  def wt(key)
    # workflow translation
    prefix = Rails.configuration.workflow_translation_prefix
    t("#{prefix}#{key}")
  end
end
