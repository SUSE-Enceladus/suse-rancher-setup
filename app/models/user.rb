class User
  include Authenticateable
  include ActiveModel::Model

  attr_accessor(:username, :password, :authorized_at)

  def self.load(authorized_at=nil)
    user = new(authorized_at: authorized_at)
  end

  def authorize!
    raise SecurityError unless username_is_valid?(self.username)
    raise SecurityError unless password_is_valid?(self.password)

    self.authorized_at = DateTime.now
  end

  def authorize
    self.authorize!
  rescue SecurityError
    errors.add(:base, :invalid)
    return nil
  end

  def is_authorized?
    !!self.authorized_at
  end
end
