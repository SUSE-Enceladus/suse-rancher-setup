module Aws
  class AwsResource < Resource
    after_initialize :set_cli, :set_framework_attributes
    before_create :aws_create
    after_save :set_framework_attributes
    before_destroy :aws_destroy

    attr_accessor :cli, :framework_attributes

    def wait_until(desired_status)
      status = ''
      while status != desired_status.to_s
        logger.info "#{self.type} #{self.id} waiting to be #{desired_status}..."
        begin
          self.refresh()
          status = self.state_attribute()
          sleep(10) if status != desired_status
        rescue
          status = 'nope'
          sleep(10)
        end
      end
      self
    end

    def refresh
      self.framework_raw_response = self.describe_resource()
      self.set_framework_attributes()
    end

    def status
      self.state_attribute
    end

    private

    def set_cli
      @cli = Aws::Cli.load()
    end

    def set_framework_attributes
      @framework_attributes = begin
        JSON.parse(self.framework_raw_response)
      rescue
        {}
      end
    end

    def aws_create
      # Call create functions in AWS CLI
      # must be implemented in child class
      raise NotImplementedError
    end

    def aws_destroy
      # call cleanup and destroy functions in AWS CLI
      # must be implemented in child class
      raise NotImplementedError
    end

    def describe_resource
      # call describe function in AWS CLI
      # must be implemented in child class
      raise NotImplementedError
    end

    def state_attribute
      # describe resource via AWS CLI and return 'State' attribute
      # must be implemented in child class
      raise NotImplementedError
    end
  end
end
