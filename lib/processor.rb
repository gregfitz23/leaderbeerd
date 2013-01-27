require File.join(Leaderbeerd::Config.root_dir, "app/models/checkin")
require File.join(Leaderbeerd::Config.root_dir, "app/models/user")
require File.join(Leaderbeerd::Config.root_dir, "lib/checkin_parser")

module Leaderbeerd
  class Processor
  
    def process(*usernames)
      options = {}
      
      options[:where] = { :username => usernames } unless usernames.empty?
      
      users = Leaderbeerd::User.all(options)
      
      users.each do |user|
        Config.logger.debug "Fetching checkins for #{user.username}"
        untappd = NRB::Untappd::API.new(access_token: user.access_token)
        
        
        begin
          resp = untappd.user_feed(
            username: user.username, 
            limit: 5
          )

          resp_meta = resp.body.meta
          if resp_meta.code == 200
            checkins = resp.body.response.checkins.items
            checkins.each do |checkin_data| 
              checkin = CheckinParser::parse_into_checkin(checkin_data)
              checkin.save
            end
          else #untappd api error
            Config.logger.error "Untappd API error: #{resp_meta.error_detail}"
          end
        rescue #general processing error
          Config.logger.error "Caught error processing #{user.username}: #{$!.message}\n#{$!.backtrace}" 
        end
        
      end
    end
    
  end
end