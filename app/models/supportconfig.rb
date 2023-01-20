require 'cheetah'

class Supportconfig
  class NotGeneratedError < StandardError; end

  attr_reader :generated_at

  def initialize(dir: Rails.root.join('public'))
    @dir = dir
    @generated_at = KeyValue.get('supportconfig_generated_at')
  end

  def generate()
    stdout, stderr = Cheetah.run(
      %W(
        supportconfig -Q -g -k
        -B #{self.filename_element}
        -R #{@dir}
      ),
      stdout: :capture,
      stderr: :capture,
      logger: Logger.new(Rails.configuration.cli_log)
    )
    @generated_at = DateTime.now
    KeyValue.set('supportconfig_generated_at', @generated_at)
  end

  def generated?()
    !!@generated_at
  end

  def download_path()
    raise NotGeneratedError unless @generated_at
    @dir + '/' + 'scc_' + self.filename_element + '.' + self.extension
  end

  private

  def extension()
    'tgz' # matches -g argument to `supportconfig`
  end

  def filename_element()
    "suse-rancher-setup_#{Rails.configuration.workflow}"
  end
end
