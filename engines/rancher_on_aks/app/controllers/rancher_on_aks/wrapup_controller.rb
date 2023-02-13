module RancherOnAks
  class WrapupController < RancherOnAks::ApplicationController

    def show
      @fqdn = RancherOnAks::Fqdn.load()
      @password = Helm::Rancher.last.initial_password
      @resource_group = Azure::ResourceGroup.first
      @cluster = Azure::Cluster.last
      @resources = Resource.where.associated(:steps)

      render(:success)
    end
  end
end
