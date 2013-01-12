require File.join(Leaderbeerd::Config.root_dir, "app/models/checkin")
require File.join(Leaderbeerd::Config.root_dir, "lib/checkin_parser")

module Leaderbeerd
  class Processor
  
    def initialize
      @untappd = NRB::Untappd::API.new(access_token: Config.untappd_access_token)
    end
  
    def process
      Config.untappd_usernames.each do |username|
        Config.logger.debug "Fetching checkins for #{username}"
        
        begin
          resp = @untappd.user_feed(
            username: username, 
            limit: 5
          )

          Config.logger.debug resp.body.inspect
          
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
          Config.logger.error "Caught error processing #{username}: #{$!.message}\n#{$!.backtrace}" 
        end
        
      end
    end
    
  end
end