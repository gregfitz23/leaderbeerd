require 'aws-sdk'
require 'benchmark'
require File.join(Leaderbeerd::Config.root_dir, "lib/checkin_parser")

module Leaderbeerd
  class Checkin
    
    ATTRIBUTES = [
      :username, 
      :timestamp, 
      :checkin_id,
      :beer_id,
      :beer_name,
      :beer_label_url,
      :beer_abv,
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
    
    ATTRIBUTES.each {|a| attr_accessor a }
    
    class << self
      
      def table
        return @table if @table
        
        @db ||= AWS::SimpleDB.new(
          :access_key_id => Config.aws_key,
          :secret_access_key => Config.aws_secret
        )

        @table = @db.domains["leaderbeerd_checkins"]          
        @table
      end

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
      
      def all
        items = []
        self.table
          .items
          .select(:all)
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
        refreshed = CheckinParser::parse_into_checkin(checkin_data)
        refreshed.save
      end
      
      private      
      def item_to_model(item)
        attributes = {
          checkin_id: item.name.to_i          
        }
        
        data_attributes = item.respond_to?(:data) ? item.data.attributes : item.attributes
        (ATTRIBUTES - [:checkin_id]).each do |a| 
          values = data_attributes[a.to_s]
          if values
            attributes.merge!({a => values.select {|v| !v.nil?}.first })
          end
        end
        
        self.new(attributes)
      end
    end
    
    def initialize(attributes = {})
      attributes.each_pair do |name, value|
        self.__send__("#{name}=", value) if ATTRIBUTES.include?(name)
      end
    end
    
    def save
      item = self.class.table.items[self.checkin_id]
      attrs = ATTRIBUTES.inject({}) do |hash, attribute|
        hash.merge({attribute => self.send(attribute) })
      end
      item.attributes.add(attrs)      
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