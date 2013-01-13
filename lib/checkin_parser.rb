module Leaderbeerd
  class CheckinParser


    def self.parse_into_checkin(checkin_data)
      checkin_id = checkin_data.checkin_id
      user = checkin_data.user
      beer = checkin_data.beer
      brewery = checkin_data.brewery
      venue = checkin_data.venue
      comments = checkin_data.comments
      toasts = checkin_data.toasts
    
      username = user.user_name

      created_at = DateTime.parse(checkin_data.created_at).to_time.to_i
      
      Checkin.new(
        checkin_id: checkin_id,
        username: user.user_name,
        beer_id: beer.bid,
        beer_name: beer.beer_name,
        beer_label_url: beer.beer_label,
        beer_abv: beer.beer_abv,
        brewery_id: !brewery.empty? ? brewery.brewery_id : nil,
        brewery_name: !brewery.empty? ? brewery.brewery_name : nil,
        brewery_country: !brewery.empty? ? brewery.country_name : nil,
        brewery_state: !brewery.empty? && !brewery.location.empty? ? brewery.location.brewery_state : nil,
        venue_id: !venue.empty? ? venue.venue_id : nil,
        venue_name: !venue.empty? ? venue.venue_name : nil,
        venue_lat: !venue.empty? && !venue.location.empty? ? venue.location.lat : nil,
        venue_lng: !venue.empty? && !venue.location.empty? ? venue.location.lng : nil,
        comment_count: comments[:count],
        toast_count: toasts[:count],
        timestamp: created_at,
        rating: checkin_data.rating_score,
        checkin_comment: checkin_data.checkin_comment
      )
    end
    

  end
end
