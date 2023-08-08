module Azure
  class Metadata
    def self.get_subscription
      RestClient.get(
        'http://169.254.169.254/metadata/instance/compute/subscriptionId',
        {
          params: {
            'api-version' => '2021-12-13',
            'format' => 'text'
          },
          Metadata: 'true'
        }
      ).body
    rescue StandardError
      ''
    end
  end
end
