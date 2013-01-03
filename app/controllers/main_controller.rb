require 'sinatra'
require File.join(Leaderbeerd::Config.root_dir, 'app/models/checkin')

module Leaderbeerd
  class MainController < Sinatra::Base
    
    set :root, File.join(Leaderbeerd::Config.root_dir, "app/controllers")
    set :views, File.join(Leaderbeerd::Config.root_dir, "app/views/main")
    
    get "/main/overview" do
      
      @usernames = Config.untappd_usernames
      
      @data = {}
      checkins = Checkin.all
      checkins.each do |checkin|
        
        @data[Time.at(checkin.timestamp).strftime("%D")] ||= {}
        @data[Time.at(checkin.timestamp).strftime("%D")][checkin.username] ||= 0
        @data[Time.at(checkin.timestamp).strftime("%D")][checkin.username] += 1
      end
      
      @overview_data = []
      @overview_data << (['Date'] + @usernames)
      @data.to_a.each do |flattened|
        ar = @usernames.map {|un| flattened.last[un] || 0 }
        ar = [flattened.first] + ar
        @overview_data << ar
      end
      
      @geo_data = {"Country" => "Beers"}
      checkins.each do |checkin|
        @geo_data[checkin.brewery_country] ||= 0 
        @geo_data[checkin.brewery_country] += 1
      end
      
      @geo_data.select! {|key, value| !key.nil?}
    
      haml :overview
    end
  end
end
