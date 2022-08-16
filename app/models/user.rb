class User
  include Authenticateable
  include ActiveModel::Model

  attr_accessor(:username, :password)

  def self.load
    new()
  end

  def authorize!
    raise SecurityError unless username_is_valid?(self.username)
    raise SecurityError unless password_is_valid?(self.password)

    KeyValue.set(:authorized_at, DateTime.now)
  end

  def authorize
    self.authorize!
  rescue SecurityError
    errors.add(:base, :invalid)
  end

  def is_authorized?
    KeyValue.get(:authorized_at, false)
  end
end
