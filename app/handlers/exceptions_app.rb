class ExceptionsApp < Rambulance::ExceptionsApp
  before_action :set_locals

  def bad_request
    render :generic
  end

  def conflict
    render :generic
  end

  def internal_server_error
    supportconfig = Supportconfig.new(dir: Rails.root.join('public'))
    supportconfig.generate unless supportconfig.generated?
    @supportconfig = '/' + supportconfig.output_filename
  rescue StandardError => e
    @locals = {
      error_class: e.class.name,
      error_message: e.message
    }
    render :total_fail
  end

  def method_not_allowed
    render :generic
  end

  def not_acceptable
    render :generic
  end

  def not_found
    @locals = {
      path: request.original_fullpath
    }
  end

  def not_implemented
    render :generic
  end

  def unprocessable_entity; end

  private

  def set_locals()
    @locals = {}
  end

  rescue_from ActionController::MissingExactTemplate do
    render :generic
  end
end
