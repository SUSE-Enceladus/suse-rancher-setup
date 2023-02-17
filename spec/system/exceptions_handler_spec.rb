require 'web_helper'
include Rambulance::TestHelper

RSpec.describe ExceptionsApp, type: :system do
  before(:all) do
    driven_by(:rack_test)
  end

  before(:example) do
    allow_any_instance_of(WelcomeController).to receive(:authorize).and_return(true)
    cheetah_vcr(context: 'exceptions_handler')
  end

  @exceptions = {
    ActionController::RoutingError => :internal_server_error,
    AbstractController::ActionNotFound => :not_found,
    ActionController::MethodNotAllowed => :method_not_allowed,
    ActionController::UnknownHttpMethod => :method_not_allowed,
    ActionController::NotImplemented => :not_implemented,
    ActionController::UnknownFormat => :not_acceptable,
    ActionDispatch::Http::MimeNegotiation::InvalidType => :not_acceptable,
    ActionController::MissingExactTemplate => :not_acceptable,
    ActionController::InvalidAuthenticityToken => :unprocessable_entity,
    ActionController::InvalidCrossOriginRequest => :unprocessable_entity,
    ActionDispatch::Http::Parameters::ParseError => :internal_server_error,
    ActionController::BadRequest => :bad_request,
    ActionController::ParameterMissing => :internal_server_error,
    Rack::QueryParser::ParameterTypeError => :bad_request,
    Rack::QueryParser::InvalidParameterError => :bad_request,
    ActiveRecord::RecordNotFound => :not_found,
    ActiveRecord::StaleObjectError => :conflict,
    ActiveRecord::RecordInvalid => :unprocessable_entity,
    ActiveRecord::RecordNotSaved => :unprocessable_entity
}

  @exceptions.each do |exception, http_status|
    it "handles #{exception.to_s}" do
      # set up the error
      expect_any_instance_of(WelcomeController).to receive(:greeting).and_raise(exception)

      # make sure supportconfig gets called on a 500
      if http_status == :internal_server_error
        expect_any_instance_of(Supportconfig).to receive(:generate).and_call_original
      end

      with_exceptions_app do
        visit("/welcome") # WelcomeController#greeting -> boom
      end
      # ensure status code matches expectations
      expect(page).to have_http_status(http_status)
    end
  end

  it 'handles supportconfig exceptions' do
    # in the event that running supportconfig falls over, we should at least give the customer a page showing the exception.
    expect_any_instance_of(WelcomeController).to receive(:greeting).and_raise(StandardError)
    expect_any_instance_of(Supportconfig).to receive(:generate).and_raise(Supportconfig::NotGeneratedError)

    with_exceptions_app do
      visit("/welcome")
    end
    expect(page).to have_http_status(:internal_server_error)
    expect(page).to have_content("Supportconfig::NotGeneratedError")
  end
end
