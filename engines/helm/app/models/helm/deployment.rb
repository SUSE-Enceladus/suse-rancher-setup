require 'json'

module Helm
  class Deployment < Resource
    before_create :helm_create_deployment
    before_destroy :helm_delete_deployment

    def refresh
      @cli ||= Helm::Cli.load
      self.framework_raw_response = @cli.describe_deployment
      @response = JSON.parse(self.framework_raw_response)
    end

    private

    def helm_create_deployment
      self.engine = 'Aws'

      prepare_cluster_for_rancher
      install_upgrade_rancher
      @cli ||= Helm::Cli.load
      self.framework_raw_response = @cli.create_deployment(
        "rancher.aws.bear454.com"
        # @zone_name[0..@zone_name.length - 2]
      )
      kubectl_cli ||= K8s::Cli.load
      stdout = kubectl_cli.get_rancher_deployment_status
      self.id = "deployment failed" unless stdout.include?("successfull")

      self.id = "rancher.aws.bear454.com" if stdout.include?("successfull")
      puts self.framework_raw_response
    end

    def prepare_cluster_for_rancher
      @aws_cli ||= Aws::Cli.load
      @aws_cli.update_kube_config("curated-installer-cluster")
      repo_url = "https://kubernetes.github.io/ingress-nginx"
      repo_name = "ingress-nginx"
      @cli ||= Helm::Cli.load
      @cli.add_repo(repo_name, repo_url)
      @cli.install_ingress(repo_name)
      kubectl_cli ||= K8s::Cli.load
      # CREATE DNS IN ROUTE53
      lb_ip = kubectl_cli.get_load_balancer_ip(repo_name)
      lb_ip = JSON.parse(lb_ip)
      lb_ip = lb_ip['status']['loadBalancer']['ingress'][0]['hostname']
      hosted_zones_raw_response = @aws_cli.get_hosted_zones("aws.bear454.com")
      hosted_zones_response = JSON.parse(hosted_zones_raw_response)
      hosted_zone_id = ''
      hosted_zone_name = ''
      hosted_zones_response['HostedZones'].each do |hosted_zone|
        if hosted_zone['Name'] == "aws.bear454.com."
          hosted_zone_id = hosted_zone['Id']["/hostedzone/".length..-1]
          hosted_zone_name = hosted_zone['Name']
        end
      end
      @zone_name = "rancher." + hosted_zone_name
      route_53_record_response = @aws_cli.create_dns_record(
        hosted_zone_id, @zone_name, lb_ip
      )
      dns_create_response = JSON.parse(route_53_record_response)
      create_dns_id = dns_create_response['ChangeInfo']['Id']
      get_change_response = @aws_cli.route53_get_change(create_dns_id)
      dns_create_response = JSON.parse(get_change_response)
      status = dns_create_response['ChangeInfo']['Status']
      while status != 'INSYNC'
        get_change_response = @aws_cli.route53_get_change(create_dns_id)
        dns_create_response = JSON.parse(get_change_response)
        status = dns_create_response['ChangeInfo']['Status']
      end
    end

    def install_upgrade_rancher
      @cli ||= Helm::Cli.load
      repo_name = "rancher-stable"
      @cli.add_repo(repo_name, "https://releases.rancher.com/server-charts/stable")
      kubectl_cli ||= K8s::Cli.load
      kubectl_cli.create_namespace
      kubectl_cli.update_cdr
      @cli.add_repo("jetstack", "https://charts.jetstack.io")
      @cli.install_cert_manager
    end

    # def helm_delete_deployment
    #   @cli ||= Helm::Cli.load
    #   @cli.delete_deployment(self.id)
    # end
  end
end
