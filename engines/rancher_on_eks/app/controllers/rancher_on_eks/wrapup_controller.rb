module RancherOnEks
  class WrapupController < RancherOnEks::ApplicationController

    def show
      @resources = Resource.where.associated(:steps)
      render(:failed) and return if Rails.configuration.lasso_error.present?

      @fqdn = RancherOnEks::Fqdn.load.value
      @password = Helm::Rancher.last.initial_password
      @region = AWS::Region.load.value
      @cluster_name = AWS::Cluster.last.id

      render(:success)
    end

    def download
      RancherOnEks::Deployment.new.record_rollback()
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
