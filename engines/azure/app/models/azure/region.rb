module Azure
  # singular class for wrapping Azure region selection
  class Region
    include ActiveModel::Model
    include Saveable

    attr_accessor(:value)

    def self.load
      new(
        value: KeyValue.get(:azure_region)
      )
    end

    def options
      # https://learn.microsoft.com/en-us/azure/reliability/availability-zones-service-support#azure-regions-with-availability-zone-support
      [
        ['Australia East', 'australiaeast'],
        ['Brazil South', 'brazilsouth'],
        ['Canada Central', 'canadacentral'],
        ['Central India', 'centralindia'],
        ['Central US', 'centralus'],
        ['East Asia', 'eastasia'],
        ['East US', 'eastus'],
        ['East US 2', 'eastus2'],
        ['France Central', 'francecentral'],
        ['Germany West Central', 'germanywestcentral'],
        ['Japan East', 'japaneast'],
        ['Korea Central', 'koreacentral'],
        ['North Europe', 'northeurope'],
        ['Norway East', 'norwayeast'],
        ['Qatar Central', 'qatarcentral'],
        ['Southeast Asia', 'southeastasia'],
        ['South Africa North', 'southafricanorth'],
        ['South Central US', 'southcentralus'],
        ['Sweden Central', 'swedencentral'],
        ['Switzerland North', 'switzerlandnorth'],
        ['UAE North', 'uaenorth'],
        ['UK South', 'uksouth'],
        ['West Europe', 'westeurope'],
        ['West US 2', 'westus2'],
        ['West US 3', 'westus3']
      ]
    end

    def save!
      KeyValue.set(:azure_region, @value)
      Azure::Cli.load.set_default_region(@value)
    end
  end
end
