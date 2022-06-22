class Login < ApplicationRecord

  attr_accessor(:username, :password)

  def self.load
    new(username: '', password: '')
  end
end
