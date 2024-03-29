class Resource < ApplicationRecord
  before_create :create_command
  after_find :setup
  after_save :set_framework_attributes
  before_destroy :destroy_command

# because STI
  has_many :steps, foreign_key: 'resource_id', inverse_of: 'resource'

  serialize :creation_attributes
  attr_reader :response
  attr_reader :framework_attributes

  def refresh
    self.framework_raw_response = self.describe_resource()
    self.set_framework_attributes()
  end

  def status
    self.state_attribute
  end

  def wait_until(desired_status)
    status = ''
    while status != desired_status.to_s
      logger.info "#{self.type} #{self.id} waiting to be #{desired_status}..."
      begin
        self.refresh()
        status = self.state_attribute()
        return self if status == desired_status.to_s
        if status.downcase.include? 'failed'
          @failed = true
          message = "Status of #{ApplicationController.helpers.friendly_type(self.type)} #{self.id} failed, deployment interrupted. Please, go to the next page\n"
          Rails.logger.error message
          Rails.configuration.lasso_error = message
          desired_status = status.to_sym
          next
        end
      rescue
        Rails.logger.error "An error happened while getting the status of #{ApplicationController.helpers.friendly_type(self.type)} #{self.id}"
        status = 'nope'
      end
      sleep(10) if status != desired_status.to_s
    end
    self
  end

  def create_command
    # Call create functions in CLI
    # must be implemented in child class
    raise NotImplementedError
  end

  def destroy_command
    # call cleanup and destroy functions in CLI
    # must be implemented in child class
    raise NotImplementedError
  end

  private

  def set_framework_attributes
    @framework_attributes = begin
      JSON.parse(self.framework_raw_response)
    rescue
      {}
    end
  end

  def setup
    self.set_framework_attributes()
    self.creation_attributes&.each do |key, value|
      self.instance_variable_set("@#{key}".to_sym, value)
    end
  end

  def describe_resource
    # call describe function in CLI
    # must be implemented in child class
    raise NotImplementedError
  end

  def state_attribute
    # describe resource via CLI and return 'State' attribute
    # must be implemented in child class
    raise NotImplementedError
  end

end
