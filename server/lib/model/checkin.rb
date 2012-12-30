require 'aws-sdk'
require 'benchmark'

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
      :venue_id,
      :venue_name,
      :comment_count,
      :toast_count
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
      
      private      
      def item_to_model(item)
        attributes = {
          checkin_id: item.name.to_i          
        }
        
        data_attributes = item.data.attributes
        (ATTRIBUTES - [:checkin_id]).each { |a| attributes.merge!({a =>data_attributes[a.to_s].first }) }
        
        self.new(attributes)
      end
    end
    
    def initialize(attributes = {})
      attributes.each_pair do |name, value|
        self.__send__("#{name}=", value) if ATTRIBUTES.include?(name)
      end
    end
    
  
  end
end