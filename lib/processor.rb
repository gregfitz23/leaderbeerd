require File.join(Leaderbeerd::Config.root_dir, "app/models/checkin")

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
              checkin = CheckinParser::parse(checkin_data)
              checkin.save
              # checkin_id = checkin.checkin_id
              # user = checkin.user
              # beer = checkin.beer
              # brewery = checkin.brewery
              # venue = checkin.venue
              # comments = checkin.comments
              # toasts = checkin.toasts
              #             
              # username = user.user_name
              # 
              # created_at = DateTime.parse(checkin.created_at).to_time.to_i
              # 
              # Checkin.create(
              #   checkin_id: checkin_id,
              #   username: user.user_name,
              #   beer_id: beer.bid,
              #   beer_name: beer.beer_name,
              #   beer_label_url: beer.beer_label,
              #   beer_abv: beer.beer_abv,
              #   brewery_id: !brewery.empty? ? brewery.brewery_id : nil,
              #   brewery_name: !brewery.empty? ? brewery.brewery_name : nil,
              #   brewery_country: !brewery.empty? ? brewery.country_name : nil,
              #   brewery_state: !brewery.empty? && !brewery.location.empty? ? brewery.location.brewery_state : nil,
              #   venue_id: !venue.empty? ? venue.venue_id : nil,
              #   venue_name: !venue.empty? ? venue.venue_name : nil,
              #   venue_lat: !venue.empty? && !venue.location.empty? ? venue.location.lat : nil,
              #   venue_lng: !venue.empty? && !venue.location.empty? ? venue.location.lng : nil,
              #   comment_count: comments.count,
              #   toast_count: toasts.count,
              #   timestamp: created_at,
              #   rating: checkin.rating_score,
              #   checkin_comment: checkin.checkin_comment
              # )
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