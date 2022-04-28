module AWS
  class Credential
    include ActiveModel::Model
    include Saveable

    attr_accessor(:aws_access_key_id, :aws_secret_access_key)

    def initialize(*args)
      super
    end

    def self.load
      new(
        aws_access_key_id: KeyValue.get(:aws_access_key_id),
        aws_secret_access_key: KeyValue.get(:aws_secret_access_key)
      )
    end

    def attributes
      {
        aws_access_key_id: @aws_access_key_id,
        aws_secret_access_key: @aws_secret_access_key
      }
    end

    def save!
      KeyValue.set(:aws_access_key_id, @aws_access_key_id)
      KeyValue.set(:aws_secret_access_key, @aws_secret_access_key)
    end

    def valid_credentials?(params)
      @cli = AWS::Cli.load
      @cli.validate_credentials(
        params[:aws_access_key_id],
        params[:aws_secret_access_key]
      )
    rescue
      false
    end
  end
end
