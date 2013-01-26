require 'sinatra'
require File.join(Leaderbeerd::Config.root_dir, 'app/models/checkin')
require File.join(Leaderbeerd::Config.root_dir, 'app/models/user')
require File.join(Leaderbeerd::Config.root_dir, 'lib/user_parser')

module Leaderbeerd
  class CheckinsController < Sinatra::Base
    enable :sessions
    set :session_secret, -> { Leaderbeerd::Config.session_secret }
    
    set :run, true
    set :port, -> { Leaderbeerd::Config.port }
    
    set :root, File.join(Leaderbeerd::Config.root_dir, "app/controllers")
    set :views, File.join(Leaderbeerd::Config.root_dir, "app/views")
    set :public_folder, File.join(Leaderbeerd::Config.root_dir, "public")
    
    before '/checkins/*' do 
      redirect "/" unless session[:username]
    end
      

    get "/health_test" do
      "hi"
    end
    
    get "/" do
      redirect "/checkins/overview" and return if session[:username]
      
      haml :"checkins/index"      
    end
    
    ###
    # USERS
    ###
    get '/users/oauth' do
      redirect "https://untappd.com/oauth/authenticate/?client_id=#{::Leaderbeerd::Config.untappd_client_id}&client_secret=#{::Leaderbeerd::Config.untappd_secret}&response_type=code&redirect_url=http://#{request.host}:#{request.port}/users/oauth_callback" 
    end

    get '/users/oauth_callback' do
      if code = params[:code]
        resp = JSON.parse(open("https://untappd.com/oauth/authorize/?client_id=#{::Leaderbeerd::Config.untappd_client_id}&client_secret=#{::Leaderbeerd::Config.untappd_secret}&response_type=code&code=#{params[:code]}&redirect_url=http://#{request.host}:#{request.port}/users/oauth_callback").read)
        access_token = resp["response"]["access_token"]

        untappd = NRB::Untappd::API.new(access_token: access_token)
        resp = untappd.user_info

        user = Leaderbeerd::UserParser.parse_into_user(resp.body.response.user)
        user.access_token = access_token
        
        friend_resp = untappd.user_friends
        friends = friend_resp.body.response.items.map {|friendship| friendship.user.user_name }
        user.friends = friends
        user.save
        
        processor = Leaderbeerd::Processor.new
        processor.process(session[:username])      
        
        session[:username] = user.username
        redirect "/"
      end
    end
    
    get "/users/refresh" do
      @user = User.find(session[:username])
      
      untappd = NRB::Untappd::API.new(access_token: @user.access_token)
      friend_resp = untappd.user_friends
      friends = friend_resp.body.response.items.map {|friendship| friendship.user.user_name }
      @user.friends = friends
      @user.save      
    end
    
    ##
    # Checkins#overview
    #
    get "/checkins/overview" do
      #setup
      @current_user = Leaderbeerd::User.find(session[:username])
      @all_usernames = @current_user.friends.dup.sort.unshift(@current_user.username)
      
      @usernames = []
      if (params[:selected_usernames])
        @usernames = params[:selected_usernames]
        session[:selected_usernames] = @usernames
        @current_user.visible_usernames = @usernames
        @current_user.save
      else
        @usernames = @current_user.visible_usernames || @all_usernames
      end
      

      @data = {}
      
      @sums_by_user = {}
      @usernames.each {|un| @sums_by_user[un] = 0 }
      
      abv_data = {}
      @usernames.each {|un| abv_data[un] = {:total => 0, :count => 0} }
      
      @counts_by_brewery = {}
      @counts_by_style = {}
      
      prev_key = nil
      checkins = Checkin.all(:where => { :username => @usernames })
      @most_recent_checkin = checkins.last
      
      checkins.each do |checkin|
        username = checkin.username
        key = Time.at(checkin.timestamp).strftime("%D")
        prev_key ||= key
        
        @data[key] ||= {}
        @data[key][username] ||= 0
        @data[key][username] += 1
        
        if prev_key != key
          @sums_by_user.each_pair {|un, sum| @data[prev_key]["#{un}_total"] = sum }
          prev_key = key
        end
        
        @sums_by_user[username] += 1
        
        abv_data[username][:total] += checkin.beer_abv
        abv_data[username][:count] += 1
        
        @counts_by_brewery[checkin.brewery_name] ||= 0
        @counts_by_brewery[checkin.brewery_name] += 1
        
        @counts_by_style[checkin.beer_style] ||= 0
        @counts_by_style[checkin.beer_style] += 1
      end
      @sums_by_user.each_pair {|un, sum| @data[prev_key]["#{un}_total"] = sum }
      
      @abv_data = {"Label" => "Value"}
      abv_data
        .each_pair { |un, count_and_sum| @abv_data[un] = count_and_sum[:count] == 0 ? 0 : (count_and_sum[:total]/count_and_sum[:count]).round(1)}
      
      @count_by_day_data = []
      @count_by_day_data << (['Date'] + @usernames*2)
      
      @data.to_a.each do |flattened|
        ar = @usernames.map {|un| flattened.last[un] || 0 } + @usernames.map {|un| flattened.last["#{un}_total"] || 0 }
        ar = [flattened.first] + ar
        @count_by_day_data << ar
      end
      
      @geo_data = { "Country" => "Beers" }
      @state_data = { "State" => "Beers" }
      checkins.each do |checkin|
        state = checkin.brewery_country == 'United States' ? checkin.brewery_state : nil
        @geo_data[checkin.brewery_country] ||= 0 
        @geo_data[checkin.brewery_country] += 1
        
        if state
          @state_data[state] ||= 0 
          @state_data[state] += 1
        end
      end
      
      @geo_data.select! {|key, value| !key.nil?}
    
      haml :"checkins/overview"
    end
    
    ##
    # Checkins#list
    #
    get "/checkins" do
      options = {
        where: {}
      }

      @filters = {}

      if (start_date = params[:start_date])
        end_date = params[:end_date] || start_date
        options[:where][:timestamp] = Date.parse(start_date).beginning_of_day.to_time.to_i .. Date.parse(end_date).end_of_day.to_time.to_i

        @filters["Start Date"] = start_date
        @filters["End Date"] = end_date
      end
      
      if (username = params[:username])
        options[:where][:username] = username
        
        @filters["Username"] = username 
      end
      
      if (state = params[:state])
        options[:where][:brewery_state] = state
        @filters["State"] = state
      end

      if (country = params[:country])
        options[:where][:brewery_country] = country
        @filters["Country"] = country
      end
      
      @checkins = Checkin.all(options)
      haml :"checkins/list"
    end
    
    ##
    # Checkin#view
    #
    get "/checkins/:checkin_id"  do
      @checkin = Checkin.find(params[:checkin_id])
      haml :"checkins/view"
    end
  end
end
