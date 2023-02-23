return unless defined?(RancherOnAks::Engine)
return unless defined?(ShirtSize::Engine)

RSpec.describe RancherOnAks::ClusterSize, type: :model do

  Azure::Region.load().options.each do |option|
    Sizeable::TYPES.each do |size|
      context "region: #{option.last}" do
        context "size: #{size}" do
          before(:each) do
            # TODO Use Cheetah VCR here
            KeyValue.set(:region, option.last)
            KeyValue.set('cluster_size', size)
          end

          before(:example) do
            cheetah_vcr(context: 'cluster_size')
          end

          it 'has an instance type' do
            expect(RancherOnAks::ClusterSize.new.instance_type).to be
          end
        end
      end
    end
  end

  context "implements the Sizeable API" do
    it 'has a dictionary of instance types' do
      expect(subject.instance_types).to be_a(Hash)
    end

    it 'has an instance count' do
      expect(subject.instance_count).to be_an(Integer)
    end

    it 'has a zones count' do
      expect(subject.zones_count).to be_an(Integer)
    end
  end
end
