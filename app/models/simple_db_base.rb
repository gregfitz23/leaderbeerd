
class SimpleDbBase
  
  cattr_accessor :table_name
  
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
  end
  
end