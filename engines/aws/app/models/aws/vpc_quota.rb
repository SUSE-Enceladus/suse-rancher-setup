module AWS
  class VpcQuota < Quota
    def limit
      JSON.parse(self.cli.get_quota(service: 'vpc', code: 'L-F678F1CE'))['Quota']['Value']
    end

    def usage
      JSON.parse(self.cli.list_vpc_ids()).length
    end

    def availability
      self.limit - self.usage
    end
  end
end
