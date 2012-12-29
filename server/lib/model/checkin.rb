require 'aws-sdk'
require 'benchmark'

module Leaderbeerd
  class Checkin
    attr_accessor :username, :timestamp, :checkin_id
    
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

      def create(username, timestamp, checkin_id)
        item = self.table.items[checkin_id]
        item.attributes.add(
          username: username,
          timestamp: timestamp
        )
        
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
        self.new(
          username: item.attributes["username"].values.first, 
          timestamp: item.attributes["timestamp"].values.first.to_i, 
          checkin_id: item.name.to_i
        )
      end
    end
    
    def initialize(attributes = {})
      self.username = attributes[:username]
      self.timestamp = attributes[:timestamp]
      self.checkin_id = attributes[:checkin_id]
    end
    
  
  end
end