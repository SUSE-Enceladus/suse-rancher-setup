module AWS
  class VpcQuota < AWS::Quota
    # https://docs.aws.amazon.com/vpc/latest/userguide/amazon-vpc-limits.html
    SERVICE = 'vpc'
    CODE = 'L-F678F1CE'

    def limit
      JSON.parse(@cli.get_quota(service: SERVICE, code: CODE))['Quota']['Value'].to_i
    end

    def usage
      JSON.parse(@cli.list_vpc_ids()).length
    end

    def required_availability
      1 # We need 1 VPC
    end
  end
end
