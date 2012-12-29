require "rubygems"
require "bundler/setup"
require "./server/lib/config"
require "./server/lib/server"
require "./server/lib/processor"

module Leaderbeerd
  

  class App < Thor
    def self.standard_options
      method_option :untappd_client_id, :type => :string, :required => true
      method_option :untappd_secret, :type => :string, :required => true 
      method_option :untappd_access_token, :type => :string, :required => true 
      method_option :untappd_usernames, :type => :array, :required => true 
      method_option :aws_key, :type => :string, :required => true 
      method_option :aws_secret, :type => :string, :required => true
    end
    
    desc "process_once", "run the leaderbeerd processor once"
    standard_options
    def process_once
      process_options(options)
      processor = ::Leaderbeerd::Processor.new
      puts "Processing..."
      processor.process
      puts "Processing completed"
    end

    desc "process", "run the leaderbeerd processor continuously"
    standard_options
    method_option :frequency, :type => :numeric, :default => 15, :desc => "Delay between runs, in minutes"
    def process
      process_options(options)
      processor = ::Leaderbeerd::Processor.new
      while true
        puts "Processing..."
        processor.process
        puts "Processing completed.  Sleeping for #{options[:frequency]} minutes."
        sleep(options[:frequency] * 60)
      end
    end

  
    desc "server", "start the http server"
    standard_options
    def server
      process_options(options)
      ::Leaderbeerd::Server.run!
    end
    
    private
    def process_options(options)
      ::Leaderbeerd::Config.untappd_client_id = options[:untappd_client_id]
      ::Leaderbeerd::Config.untappd_secret = options[:untappd_secret]
      ::Leaderbeerd::Config.untappd_access_token = options[:untappd_access_token]
      ::Leaderbeerd::Config.untappd_usernames = options[:untappd_usernames]
      ::Leaderbeerd::Config.aws_key = options[:aws_key]
      ::Leaderbeerd::Config.aws_secret = options[:aws_secret]      
    end
  end
end