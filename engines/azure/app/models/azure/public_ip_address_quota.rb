module Azure
  class PublicIpAddressQuota < Azure::Quota
    VALUE = 'PublicIPAddresses'

    def required_availability
      1 # 1 public IP address required for cluster load balancer
    end

    private

    def usage_report
      @usage_report ||= @cli.list_network_usage(value: VALUE)
    end
  end
end
