RSpec.describe Supportconfig, :type => :model do
  subject { Supportconfig.new(dir: '/tmp') }

  let(:expected_download_path) { "/tmp/scc_suse-rancher-setup_#{Rails.configuration.workflow}.tgz" }

  before(:example) do
    cheetah_vcr()
  end

  it 'generates a supportconfig' do
    expect(subject.generate()).to be_truthy
    expect(subject.generated?).to be_truthy
    expect(subject.download_path).to eq(expected_download_path)
  end

  it 'raises an exception if not generated' do
    expect(subject.generated?).to be_falsey
    expect { subject.download_path }.to raise_error(Supportconfig::NotGeneratedError)
  end
end
