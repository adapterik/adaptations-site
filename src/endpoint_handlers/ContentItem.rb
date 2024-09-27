require_relative './EndpointHandler'

class ContentItem < EndpointHandler
  def initialize(context, input)
    super(context, input)
    @content_type_id = context[:arguments][0]
    @content_id = context[:arguments][1]
  end

  def include_content()
    template = ERB.new @context[:content]['content']
    fulfilled_content = template.result binding
    rendered = Kramdown::Document.new(fulfilled_content, :input => 'GFM', :syntax_highlighter => 'rouge').to_html
    set_rendered(@context[:content_id], rendered)
  end

  def handle_get()
    # Here we fetch the associated item
    content = @site_db.get_content(@content_type_id, @content_id)

    content_type = @site_db.get_content_type @content_type_id

    # If we can't find the content, we set the content to the "Not Found" content.
    if content.nil?
        original_content_id = @content_id
        content = @site_db.get_system_page 'not_found'
        content[:original_content_id] = original_content_id
    end

    # Next status 
    next_status = case content['status_id']
    when 'draft' 
      'published'
    when 'published'
      'retracted'
    when 'retracted'
      'draft'
    end

    content['next_status'] = next_status

    # We now abstract the "page" to be anything that affects the overall 
    # and generic information about the page.
    @context[:page] = {
      'title' => content['title']
    }

    # Create the context object, which is a merging of
    # - the site, contemnt def, menu, etc. see below
    request = {
      ip: ENV['REMOTE_ADDR'],
      referrer: ENV['HTTP_REFERER'],
      ui: ENV['HTTP_USER_AGENT']
    }

    @context.merge!({
      site: @site,
      content_id: @content_id,
      content: content,
      content_type: content_type,
      env: {
        request: request
      },
    })

    # template = load_endpoint_template
    load_endpoint_template().result binding
  end
end