require 'aws-sdk'
require 'benchmark'

module Leaderbeerd
  class Checkin
    attr_accessor :username, :timestamp, :checkin_id
    
    class << self
      
      def table
        return @table if @table
        
        @dynamo_db ||= AWS::DynamoDB.new(
          :access_key_id => Config.aws_key,
          :secret_access_key => Config.aws_secret
        )

        @table = @dynamo_db.tables["leaderbeerd_checkins"]          
        @table.hash_key = [:username, :string]
        @table.range_key = [:timestamp, :number]
        @table
      end

      def create(username, timestamp, checkin_id)
        item = self.table.items.put(
          username: username,
          timestamp: timestamp,
          checkin_id: checkin_id
        )
        
        item_to_model(item)
      end
      
      ##
      # Find all checkins by a user after the given timestamp.
      #
      def find_all_by_username_after_timestamp(username, since)       
        self.table.items.query(:hash_value => username, :range_greater_than => since).map {|item| item_to_model(item) }
      end
      
      private      
      def item_to_model(item)
        attrs = item.attributes
        self.new(username: attrs["username"], timestamp: attrs["timestamp"], checkin_id: attrs["checkin_id"])
      end
    end
    
    def initialize(attributes = {})
      self.username = attributes[:username]
      self.timestamp = attributes[:timestamp]
      self.checkin_id = attributes[:checkin_id]
    end
    
  
  end
end