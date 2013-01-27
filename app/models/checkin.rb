require 'aws-sdk'
require 'benchmark'
require File.join(Leaderbeerd::Config.root_dir, 'app/models/simple_db_base')
require File.join(Leaderbeerd::Config.root_dir, "lib/checkin_parser")

module Leaderbeerd
  class Checkin < ::SimpleDbBase
    
    self.table_name = "leaderbeerd_checkins"
    
    self.attributes = [
      :username, 
      :timestamp, 
      :checkin_id,
      :beer_id,
      :beer_name,
      :beer_label_url,
      :beer_abv,
      :beer_style,
      :brewery_id,
      :brewery_name,
      :brewery_state,
      :brewery_country,
      :venue_id,
      :venue_name,
      :comment_count,
      :toast_count,
      :checkin_comment,
      :rating
    ]
    
    class << self
      
      def create(attributes)
        [:checkin_id, :username, :timestamp].each {|a| raise "#{a} is required" if attributes[a].to_s.empty? }
        
        Config.logger.debug "Creating leaderbeerd_checkin with #{attributes.inspect}"
        
        item = self.table.items[attributes[:checkin_id]]
        item.attributes.add(attributes)
        
        item_to_model(item)
      end
      
      def find(id)
        item_to_model(table.items[id])
      end
      
      def find_most_recent_by_username(username)
        item = self.table
          .items
          .where(
            username: username, 
          )
          .order(:timestamp, :desc)
          .limit(1)
          .first
          
          item_to_model(item)
      end
      
      def find_all_by_username(username)
        items = []
        self.table
          .items
          .select(:all)
          .where(:username => username)
          .order(:timestamp, :asc)
          .each {|i| items << item_to_model(i)}
          
        items        
      end
      
      ##
      # Find all checkins by a user after the given timestamp.
      #
      def count_by_username_after_timestamp(username, since)       
        self.table
          .items
          .where(
            username: username, 
            timestamp: since..Time.now.to_i
          )
          .order(:timestamp, :desc)
          .size
      end
      
      ## 
      # Retrieve checkin info from Untapped and reload the data
      #
      def refresh!(checkin)
        @untappd = NRB::Untappd::API.new(access_token: Config.untappd_access_token)
        checkin_data = @untappd.checkin_info(checkin_id: checkin.checkin_id)
        checkin = CheckinParser::parse_into_checkin(checkin_data)
        checkin.save
      end
      
      private      
    end
    
    
    # Attributes
    def rating
      @rating.to_i
    end
    
    def timestamp
      @timestamp.to_i
    end
    
    def toast_count
      @toast_count.to_i
    end
    
    def comment_count
      @comment_count.to_i
    end
   
   def beer_abv 
     @beer_abv.to_f
   end
  
  end
end