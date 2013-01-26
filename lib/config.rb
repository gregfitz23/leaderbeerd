module Leaderbeerd
  
  class Config
  
    class << self
      attr_accessor :untappd_client_id, 
                    :untappd_secret, 
                    :untappd_access_token, 
                    :aws_key, 
                    :aws_secret, 
                    :untappd_usernames,
                    :logger,
                    :asset_host,
                    :port,
                    :session_secret
                    
      def root_dir
        File.join(File.dirname(__FILE__), "..")
      end
      
                    
    end  
  end
end