RSpec.describe Executable, type: :model do
  it 'provides an interface that must be implemented' do
    expect { subject.environment }.to raise_error(NotImplementedError)
    expect { subject.command }.to raise_error(NotImplementedError)
  end

  it 'implements an interface to cheetah' do
    def subject.environment
      { 'BAR' => 'baz' }
    end

    def subject.command
      'foo'
    end

    expect(Cheetah).to receive(:run).with(
      ['foo', 'de', 'bar'],
      stdout: :capture,
      stderr: :capture,
      env: { 'BAR' => 'baz' },
      logger: instance_of(Logger)
    )
    subject.execute(%w(de bar))
  end
end
