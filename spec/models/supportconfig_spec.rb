RSpec.describe Supportconfig, :type => :model do
  subject { Supportconfig.new(dir: '/tmp') }

  let(:expected_output_path) { "/tmp/scc_suse-rancher-setup_#{Rails.configuration.workflow}.tgz" }

  before(:example) do
    cheetah_vcr(context: 'supportconfig')
  end

  it 'generates a supportconfig' do
    expect(subject.generate()).to be_truthy
    expect(subject.generated?).to be_truthy
    expect(subject.output_path.to_s).to eq(expected_output_path)
  end

  it 'raises an exception if not generated' do
    expect(subject.generated?).to be_falsey
    expect { subject.output_path }.to raise_error(Supportconfig::NotGeneratedError)
  end
end
