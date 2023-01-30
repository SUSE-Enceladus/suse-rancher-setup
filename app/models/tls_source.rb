class TlsSource
  include ActiveModel::Model
  include Saveable

  SOURCE_OPTIONS = %w(rancher letsEncrypt)

  attr_accessor :source, :email_address
  validates :source, allow_nil: true, inclusion: {
    in: SOURCE_OPTIONS,
    message: "'%{value}' is not valid."
  }
  with_options if: -> { source == 'letsEncrypt' } do |instance|
    instance.validates :email_address, presence: true
    instance.validates :email_address, email: true
  end

  def self.load
    new(
      source: KeyValue.get(:tls_source),
      email_address: KeyValue.get(:tls_email_address)
    )
  end

  def save!
    self.validate!
    KeyValue.set(:tls_source, @source)
    KeyValue.set(:tls_email_address, @email_address)
  end

  def source_options
    [
      ["Rancher self-signed certificate", 'rancher'],
      ["Let's Encrypt certificate", 'letsEncrypt']
    ]
  end
end
