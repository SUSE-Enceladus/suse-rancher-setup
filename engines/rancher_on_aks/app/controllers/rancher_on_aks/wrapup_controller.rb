module RancherOnAks
  class WrapupController < RancherOnAks::ApplicationController

    def show
      @resources = Resource.where.associated(:steps)
      render(:failed) and return if Rails.configuration.lasso_error.present?

      @fqdn = RancherOnAks::Fqdn.load()
      @password = Helm::Rancher.last.initial_password
      @resource_group = Azure::ResourceGroup.first
      @cluster = Azure::Cluster.last

      render(:success)
    end

    def download
      KeyValue.set(:azure_defaults_set, false) # force re-setting defaults for recording
      RancherOnAks::Deployment.new.record_rollback()
      @env_vars = KeyValue.get(:recorded_env_vars, {})
      @commands = KeyValue.get(:recorded_commands, [])
      filename = "#{helpers.wt('product_brand.title').parameterize}-cleanup-#{DateTime.now.iso8601}.txt"
      send_data(
        render_to_string(:download, layout: false),
        filename: filename,
        type: 'text/plain',
        disposition: 'attachment'
      )
    end
  end
end
