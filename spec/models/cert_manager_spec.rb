return unless defined?(Helm::Engine)

RSpec.describe Helm::CertManager, type: :model do
  let(:expected_namespace) { 'cert-manager' }
  let(:expected_repo_name) { 'jetstack' }
  let(:expected_repo_url) { 'https://charts.jetstack.io' }
  let(:expected_release_name) { 'cert-manager' }
  let(:expected_chart) { 'jetstack/cert-manager' }
  let(:expected_version) { '1.5.1' }

  context 'on create' do
    before do
      # don't actually execute anything
      allow(Cheetah).to receive(:run).and_return(true)

      # mock out things we're not testing
      allow(subject).to receive(:refresh)

      # mock kubectl CLI
      @mock_kubectl = double
      subject.instance_variable_set(:@kubectl, @mock_kubectl)

      # mock helm CLI
      @mock_helm = double
      subject.instance_variable_set(:@helm, @mock_helm)
    end

    it 'delegates the expected calls' do
      # create the namespace & update crds via kubectl
      expect(@mock_kubectl)
        .to receive(:create_namespace).with(expected_namespace)
      expect(@mock_kubectl)
        .to receive(:update_crds).with({version: expected_version})
      # add the helm repo
      expect(@mock_helm)
        .to receive(:add_repo).with(expected_repo_name, expected_repo_url)
        .and_return(true)
      # install rancher via helm
      expect(@mock_helm)
        .to receive(:install)
        .with(
          expected_release_name,
          expected_chart,
          expected_namespace,
          [
            '--version',
            expected_version
          ]
        ).and_return(true)

      # do it already
      subject.save!
    end


  end
end
