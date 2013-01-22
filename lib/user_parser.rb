module Leaderbeerd
  class UserParser


    def self.parse_into_user(user_data)
      Leaderbeerd::User.new({
        username: user_data.user_name,
        first_name: user_data.first_name,
        last_name: user_data.last_name,
        user_avatar: user_data.user_avatar
      })
    end
  end
end