require 'rails_helper'

RSpec.describe RancherOnEks::Rancher, :type => :model do
  let(:mock_fqdn) { 'rancher.example.com' }
  let(:expected_namespace) { 'cattle-system' }
  let(:expected_repo_name) { 'rancher-stable' }
  let(:expected_repo_url) { 'https://releases.rancher.com/server-charts/stable' }
  let(:expected_release_name) { 'rancher-stable' }
  let(:expected_chart) { 'rancher-stable/rancher' }

  context 'on create' do
    before do
      # don't actually execute anything
      allow(Cheetah).to receive(:run).and_return(true)

      # mock out things we're not testing
      subject.fqdn = mock_fqdn
      allow(subject).to receive(:refresh)
    end

    it 'delegates the expected calls' do
      # create the namespace via kubectl
      mock_kubectl = double
      expect(mock_kubectl)
        .to receive(:create_namespace).with(expected_namespace)
        .and_return(true)
      subject.instance_variable_set(:@kubectl, mock_kubectl)

      # add the helm repo
      mock_helm = double
      expect(mock_helm)
        .to receive(:add_repo).with(expected_repo_name, expected_repo_url)
        .and_return(true)
      subject.instance_variable_set(:@helm, mock_helm)

      # install rancher via helm
      expect(mock_helm)
        .to receive(:install)
        .with(
          expected_release_name,
          expected_chart,
          expected_namespace,
          [
            '--set',
            "hostname=#{mock_fqdn}",
            '--set',
            'replicas=3'
          ]
        ).and_return(true)

      # do it already
      subject.save!
    end

    context 'with a version number' do
      let(:expected_version) { '2.6.6' }

      before do
        subject.version = expected_version
      end

      it 'delegates the expected calls' do
        # create the namespace via kubectl
        mock_kubectl = double
        expect(mock_kubectl)
          .to receive(:create_namespace).with(expected_namespace)
          .and_return(true)
        subject.instance_variable_set(:@kubectl, mock_kubectl)

        # add the helm repo
        mock_helm = double
        expect(mock_helm)
          .to receive(:add_repo).with(expected_repo_name, expected_repo_url)
          .and_return(true)
        subject.instance_variable_set(:@helm, mock_helm)

        # install rancher via helm
        expect(mock_helm)
          .to receive(:install)
          .with(
            expected_release_name,
            expected_chart,
            expected_namespace,
            [
              '--set',
              "hostname=#{mock_fqdn}",
              '--set',
              'replicas=3',
              '--version',
              expected_version
            ]
          ).and_return(true)

        # do it already
        subject.save!
      end
    end

    context 'custom install' do
      let(:custom_config) do
        cc = RancherOnEks::CustomConfig.new(
          repo_name: 'mock-repo-name',
          repo_url: 'mock-repo-url',
          chart: 'mock-chart',
          release_name: 'mock-release-name',
          version: 'mock-version'
        )
        cc.save
        return cc
      end

      it 'delegates with custom attributes' do
        # create the namespace via kubectl
        mock_kubectl = double
        expect(mock_kubectl)
          .to receive(:create_namespace).with(expected_namespace)
          .and_return(true)
        subject.instance_variable_set(:@kubectl, mock_kubectl)

        # add the helm repo
        mock_helm = double
        expect(mock_helm)
          .to receive(:add_repo).with(custom_config.repo_name, custom_config.repo_url)
          .and_return(true)
        subject.instance_variable_set(:@helm, mock_helm)

        # install rancher via helm
        expect(mock_helm)
          .to receive(:install)
          .with(
            custom_config.release_name,
            custom_config.chart,
            expected_namespace,
            [
              '--set',
              "hostname=#{mock_fqdn}",
              '--set',
              'replicas=3',
              '--version',
              custom_config.version
            ]
          ).and_return(true)

        # do it already
        subject.repo_name = custom_config.repo_name
        subject.repo_url = custom_config.repo_url
        subject.chart = custom_config.chart
        subject.release_name = custom_config.release_name
        subject.version = custom_config.version
        subject.save!
      end
    end
  end

  context 'internal functions' do
    before do
      subject.id = expected_release_name
    end

    it 'gets the expected helm status as describe_resource' do
      mock_helm = double
      expect(mock_helm)
        .to receive(:status).with(expected_release_name, expected_namespace)
        .and_return(true)
      subject.instance_variable_set(:@helm, mock_helm)


      subject.send(:describe_resource)
    end

    it 'gets the expected kubectl status as state_attribute' do
      mock_kubectl = double
      expect(mock_kubectl)
        .to receive(:status).with(expected_release_name, expected_namespace)
        .and_return(true)
      subject.instance_variable_set(:@kubectl, mock_kubectl)

      subject.send(:state_attribute)
    end
  end
end
