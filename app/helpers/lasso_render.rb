class LassoRender < Redcarpet::Render::HTML
  def link(link, title, content)
    %(<a href="#{link}" target="_blank" rel="noopener noreferrer">#{content}</a>)
  end
end
