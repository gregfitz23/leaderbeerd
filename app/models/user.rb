require 'aws-sdk'

module Leaderbeerd
  class User < ::SimpleDbBase
    self.table_name = "leaderbeerd_users"
    self.id_field = :username
    
    self.attributes = [
      :username,
      :first_name,
      :last_name,
      :user_avatar,
      :access_token,
      :friends
    ]
    
    def friends
      @friends.split("^|^")
    end
    
  end
end