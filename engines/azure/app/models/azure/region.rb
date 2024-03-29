module Azure
  # singular class for wrapping Azure region selection
  class Region
    include ActiveModel::Model
    include Saveable

    attr_accessor(:value)

    def self.load
      new(
        value: KeyValue.get(:region)
      )
    end

    def options
      # https://learn.microsoft.com/en-us/azure/reliability/availability-zones-service-support#azure-regions-with-availability-zone-support
      # regions commented out failed to deploy AKS to 3 zones
      [
        ['Australia East', 'australiaeast'],
        # ['Brazil South', 'brazilsouth'],
        ['Canada Central', 'canadacentral'],
        ['Central India', 'centralindia'],
        ['Central US', 'centralus'],
        ['East Asia', 'eastasia'],
        ['East US', 'eastus'],
        ['East US 2', 'eastus2'],
        # ['France Central', 'francecentral'],
        ['Germany West Central', 'germanywestcentral'],
        # ['Japan East', 'japaneast'],
        ['Korea Central', 'koreacentral'],
        # ['North Europe', 'northeurope'],
        ['Norway East', 'norwayeast'],
        # ['Qatar Central', 'qatarcentral'],
        # ['Southeast Asia', 'southeastasia'],
        ['South Africa North', 'southafricanorth'],
        # ['South Central US', 'southcentralus'],
        ['Sweden Central', 'swedencentral'],
        ['Switzerland North', 'switzerlandnorth'],
        # ['UAE North', 'uaenorth'],
        ['UK South', 'uksouth'],
        ['West Europe', 'westeurope'],
        ['West US 2', 'westus2'],
        ['West US 3', 'westus3']
      ]
    end

    def cli
      @cli ||= Azure::Interface.load
    end

    def save!
      KeyValue.set(:region, @value)
    end

    def available_instance_types
      self.cli.list_sizes(region: @value).collect{ |i| i['name'] }.sort
    rescue
      []
    end

    def to_s
      @value
    end
  end
end
