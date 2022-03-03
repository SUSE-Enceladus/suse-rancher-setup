require 'cheetah'

module Aws
  class Cli
    include ActiveModel::Model

    attr_accessor(:credential)

    def initialize(*args)
      super
    end

    def self.load
      new(
        credential: Credential.load()
      )
    end

    def execute(args=[])
      stdout, stderr = Cheetah.run(
        ['aws', *args],
        stdout: :capture,
        stderr: :capture,
        env: {
          'AWS_ACCESS_KEY_ID' => @credential.aws_access_key_id,
          'AWS_SECRET_ACCESS_KEY' => @credential.aws_secret_access_key
        }
      )
    end
  end
end
