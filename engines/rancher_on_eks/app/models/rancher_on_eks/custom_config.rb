module RancherOnEks
  class CustomConfig
    include ActiveModel::Model
    include Saveable

    attr_accessor :repo_name, :repo_url, :chart, :release_name, :version

    def self.attribute_names
      %w(repo_name repo_url chart release_name version)
    end

    def self.load
      new(
        repo_name: KeyValue.get(
          :rancher_repo_name, Rails.application.config.x.rancher.repo_name
        ),
        repo_url: KeyValue.get(
          :rancher_repo_url, Rails.application.config.x.rancher.repo_url
        ),
        chart: KeyValue.get(
          :rancher_chart, Rails.application.config.x.rancher.chart
        ),
        release_name: KeyValue.get(
          :rancher_release_name, Rails.application.config.x.rancher.release_name
        ),
        version: KeyValue.get(
          :rancher_version, Rails.application.config.x.rancher.version
        )
      )
    end

    def save!
      KeyValue.set(:rancher_repo_name, @repo_name)
      KeyValue.set(:rancher_repo_url, @repo_url)
      KeyValue.set(:rancher_chart, @chart)
      KeyValue.set(:rancher_release_name, @release_name)
      KeyValue.set(:rancher_version, @version)
    end
  end
end
