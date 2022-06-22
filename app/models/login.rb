class Login

  include ActiveModel::Model

  attr_accessor(:username, :password)

  def self.load
    new(username: '', password: '')
  end
end
