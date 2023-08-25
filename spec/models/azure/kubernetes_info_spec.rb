return unless defined?(Azure::Engine)

RSpec.describe Azure::KubernetesInfo, type: :model, vcr: true do
  describe 'with mock versions' do
    let(:mock_versions) { ['1.0.0', '1.0.1', '2.1.2'] }
    let(:mock_version) { '1.0' }
    let(:expected_version) { '1.0.1' }
    let(:subject) { Azure::KubernetesInfo.new(config_version: mock_version) }

    before do
      mock_azure_login()
      allow_any_instance_of(Azure::Interface).to receive(:get_kubernetes_versions).and_return(mock_versions)
    end

    it 'returns a list of supported k8s versions' do
      results = subject.available_versions
      expect(results).to match_array(mock_versions)
    end

    it 'returns the single highest patchlevel version matching the configured minor version' do
      result = subject.latest_matching_version
      expect(result).to eq(expected_version)
    end
  end

  describe 'with versions from Azure CLI' do
    before do
      mock_azure_login()
      KeyValue.set(:region, 'westus3')
    end

    it 'returns a list of supported k8s versions' do
      results = subject.available_versions
      expect(results).to be_an(Array)
      results.each do |result|
        expect(result).to match(/\d+\.\d+/)
      end
    end

    it 'returns a single patchlevel version matching the configured minor version' do
      result = subject.latest_matching_version
      expect(result).to match(/\d+\.\d+/)
      expect(result).to start_with(Rails.configuration.x.rancher_on_aks.k8s_version)
    end
  end
end
