require 'sinatra'
require File.join(Leaderbeerd::Config.root_dir, 'app/models/checkin')

module Leaderbeerd
  class CheckinsController < Sinatra::Base
    
    set :run, true
    set :port, 80
    set :root, File.join(Leaderbeerd::Config.root_dir, "app/controllers")
    set :views, File.join(Leaderbeerd::Config.root_dir, "app/views")
    
    get "/health_test" do
      "hi"
    end
    
    get "/" do
      #setup
      @usernames = Config.untappd_usernames
      
      @data = {}
      
      @sums_by_user = {}
      @usernames.each {|un| @sums_by_user[un] = 0 }
      
      abv_data = {}
      @usernames.each {|un| abv_data[un] = {:total => 0, :count => 0} }
      
      prev_key = nil
      checkins = Checkin.all
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
      end

      @sums_by_user.each_pair {|un, sum| @data[prev_key]["#{un}_total"] = sum }
      
      @abv_data = {"Label" => "Value"}
      abv_data.each_pair { |un, count_and_sum| @abv_data[un] = (count_and_sum[:total]/count_and_sum[:count]).round(1)}
      
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
    
      haml :"checkins/overview", :layout => false
    end
    
    get "/checkins/:checkin_id"  do
      @checkin = Checkin.find(params[:checkin_id])
      haml :"checkins/view"
    end
  end
end
