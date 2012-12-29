require 'sinatra'
require 'net/https'
require 'drink-socially'
require './server/lib/model/checkin'

module Leaderbeerd
  class Server < Sinatra::Base
    get '/auth' do
      #redirect "https://untappd.com/oauth/authenticate/?client_id=#{::Leaderbeerd::Config.untappd_client_id}&client_secret=#{::Leaderbeerd::Config.untappd_secret}&response_type=code&redirect_url=http://localhost:4567/oauth_callback" 
      redirect "http://untappd.com/oauth/authenticate/?client_id=#{::Leaderbeerd::Config.untappd_client_id}&response_type=token&redirect_url=http://localhost:4567/oauth_complete"
    end
    
    get '/oauth_complete' do
      
      @untappd = NRB::Untappd::API.new(access_token: Config.untappd_access_token)
      @untappd.user_feed(username: "gregfitz23").to_s
    end
    
    get '/stats' do      
      data = {}
      Leaderbeerd::Config.untappd_usernames.each do |username|
        data[username] = Checkin.find_all_by_username_after_timestamp(username, Time.now.to_i - (7*24*60*60)).size
      end
      
      data.inspect
    end
    
    
    def redirect_url(response)
      if response['location'].nil?
        puts response.body.inspect
        response.body.match(/<a href=\"([^>]+)\">/i)[1]
      else
        response['location']
      end
    end
    
  end
end