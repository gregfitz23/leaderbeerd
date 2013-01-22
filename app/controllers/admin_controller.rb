require 'sinatra'
require 'net/https'
require 'drink-socially'
require 'open-uri'
require File.join(Leaderbeerd::Config.root_dir, 'app/models/checkin')

module Leaderbeerd
  class AdminController < Sinatra::Base
    set :root, File.join(Leaderbeerd::Config.root_dir, "app/controllers")
    set :views, File.join(Leaderbeerd::Config.root_dir, "app/views/admin")
    
    get '/admin/auth' do
      redirect "https://untappd.com/oauth/authenticate/?client_id=#{::Leaderbeerd::Config.untappd_client_id}&client_secret=#{::Leaderbeerd::Config.untappd_secret}&response_type=code&redirect_url=http://#{request.host}:#{request.port}/admin/oauth_callback" 
      #redirect "http://untappd.com/oauth/authenticate/?client_id=#{::Leaderbeerd::Config.untappd_client_id}&response_type=token&redirect_url=http://localhost:4567/oauth_complete"
    end

    get '/admin/oauth_callback' do
      if code = params[:code]
        ::Leaderbeerd::Config.logger.debug "Redirecting to https://untappd.com/oauth/authorize/?client_id=#{::Leaderbeerd::Config.untappd_client_id}&client_secret=#{::Leaderbeerd::Config.untappd_secret}&response_type=code&code=#{code}&redirect_url=http://#{request.host}:#{request.port}/admin/oauth_callback"
        resp = JSON.parse(open("https://untappd.com/oauth/authorize/?client_id=#{::Leaderbeerd::Config.untappd_client_id}&client_secret=#{::Leaderbeerd::Config.untappd_secret}&response_type=code&code=#{params[:code]}&redirect_url=http://#{request.host}:#{request.port}/admin/oauth_callback").read)
        access_token = resp["response"]["access_token"]
      end
    end
    
    get '/oauth_complete' do      
      untappd = NRB::Untappd::API.new(access_token: Config.untappd_access_token)
      untappd.user_feed(username: "gregfitz23").to_s
    end
    
    get '/admin/stats' do      
      
      @data = Leaderbeerd::Config.untappd_usernames.inject({}) do |data, username|
        data[username] = {}
        data[username][:count] = Checkin.count_by_username_after_timestamp(username, Time.now.to_i - (7*24*60*60))
        data[username][:recent_checkin] = Checkin.find_most_recent_by_username(username)
        data
      end
      
      puts @data

      # untappd = NRB::Untappd::API.new(access_token: Config.untappd_access_token)
      untappd = NRB::Untappd::API.new(access_token: Config.untappd_access_token)
      untappd.user_feed(username: "gregfitz23")

      @rate_limit = untappd.rate_limit      
      
      haml :stats
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