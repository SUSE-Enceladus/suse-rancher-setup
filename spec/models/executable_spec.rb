RSpec.describe Executable, type: :model do
  it 'provides an interface that must be implemented' do
    expect { subject.environment }.to raise_error(NotImplementedError)
    expect { subject.command }.to raise_error(NotImplementedError)
  end
end

class MockExecutable < Executable
  def environment
    { 'BAR' => 'baz' }
  end

  def command
    'foo'
  end
end

RSpec.describe MockExecutable, type: :model do
  let(:subject) { MockExecutable.load() }

  describe 'as an inheritor of Executable' do
    it 'provides an interface to cheetah' do
      expect(Cheetah).to receive(:run).with(
        ['foo', 'de', 'bar'],
        stdout: :capture,
        stderr: :capture,
        env: { 'BAR' => 'baz' },
        logger: instance_of(Logger)
      )
      subject.execute(%w(de bar))
    end

    describe 'with recording on' do
      before do
        allow(Cheetah).to receive(:run)
        subject.do_record = true
      end

      it 'records environment variables' do
        subject.execute(%w(de bar))
        expect(KeyValue.get(:recorded_env_vars)).to eq({ 'BAR' => 'baz' })
      end

      it 'records commands' do
        subject.execute(%w(de bar))
        expect(KeyValue.get(:recorded_commands)).to eq([
          'foo de bar'
        ])
      end

      describe 'with pre-existing data' do
        before do
          KeyValue.set(:recorded_env_vars, {'FIRST' => 'env_var'})
          KeyValue.set(:recorded_commands, ['first command'])
        end

        it 'records commands sequentially' do
          subject.execute(%w(de bar))
          expect(KeyValue.get(:recorded_commands)).to eq([
            'first command',
            'foo de bar'
          ])
        end

        it 'accumulates environment variables' do
          subject.execute(%w(de bar))
          expect(KeyValue.get(:recorded_env_vars)).to eq({
            'FIRST' => 'env_var',
            'BAR' => 'baz'
          })
        end
      end
    end

    describe 'using global configuration' do
      before do
        Rails.configuration.record_commands = true
      end
      it 'can enable recording' do
        expect(subject.do_record).to be_truthy
      end

      it 'can disable execution' do
        expect(subject.do_execute).to be_falsey
      end
      after do
        Rails.configuration.record_commands = false
      end
    end
  end
end
