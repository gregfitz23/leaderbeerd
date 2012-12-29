require "./server/lib/model/checkin"

module Leaderbeerd
  class Processor
  
    def initialize
      @untappd = NRB::Untappd::API.new(access_token: Config.untappd_access_token)
    end
  
    def process
      Config.untappd_usernames.each do |username|
        resp = @untappd.user_feed(username: username, limit: 5)
        items = resp.body.response.checkins.items
        items.each do |item| 
          checkin_id = item.checkin_id
          username = item.user.user_name
          created_at = DateTime.parse(item.created_at).to_time.to_i
          
          Checkin.create(username, created_at, checkin_id)
        end
      end
    end

  end
end