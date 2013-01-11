require 'sinatra'
require File.join(Leaderbeerd::Config.root_dir, 'app/models/checkin')

module Leaderbeerd
  class CheckinsController < Sinatra::Base
    
    set :root, File.join(Leaderbeerd::Config.root_dir, "app/controllers")
    set :views, File.join(Leaderbeerd::Config.root_dir, "app/views")
    
    get "/checkins/overview" do
      
      @usernames = Config.untappd_usernames
      
      @data = {}
      
      @sums_by_user = {}
      @usernames.each {|un| @sums_by_user[un] = 0 }
      
      prev_key = nil
      checkins = Checkin.all
      checkins.each do |checkin|
        key = Time.at(checkin.timestamp).strftime("%D")
        prev_key ||= key
        
        @data[key] ||= {}
        @data[key][checkin.username] ||= 0
        @data[key][checkin.username] += 1
        
        if prev_key != key
          @sums_by_user.each_pair {|un, sum| @data[prev_key]["#{un}_total"] = sum }
          prev_key = key
        end
        
        @sums_by_user[checkin.username] += 1
      end

      @sums_by_user.each_pair {|un, sum| @data[prev_key]["#{un}_total"] = sum }
      
      @count_by_day_data = []
      @count_by_day_data << (['Date'] + @usernames*2)
      
      @data.to_a.each do |flattened|
        ar = @usernames.map {|un| flattened.last[un] || 0 } + @usernames.map {|un| flattened.last["#{un}_total"] || 0 }
        ar = [flattened.first] + ar
        @count_by_day_data << ar
      end
      
      @geo_data = {"Country" => "Beers"}
      checkins.each do |checkin|
        @geo_data[checkin.brewery_country] ||= 0 
        @geo_data[checkin.brewery_country] += 1
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
