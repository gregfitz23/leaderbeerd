require "rubygems"
require "bundler/setup"
require 'benchmark'
require 'logger'
require 'irb'

require "./lib/config"
require File.join(Leaderbeerd::Config.root_dir, "app/controllers/admin_controller")
require File.join(Leaderbeerd::Config.root_dir, "lib/processor")

module Leaderbeerd
  class App < Thor
    def self.standard_options
      method_option :untappd_client_id, :type => :string, :required => true
      method_option :untappd_secret, :type => :string, :required => true 
      method_option :untappd_access_token, :type => :string, :required => true 
      method_option :untappd_usernames, :type => :array, :required => true 
      method_option :aws_key, :type => :string, :required => true 
      method_option :aws_secret, :type => :string, :required => true
      method_option :log_file, :type => :string, :default => "log/leaderbeerd.log"
      method_option :log_level, :type => :string, :default => "INFO"
    end
    
    def self.processor_options
      method_option :pid_file, :type => :string, :default => "tmp/leaderbeerd.pid"
      method_option :force, :type => :boolean, :default => false, :desc => "Force the process to restart", :aliases => "-f"
      method_option :daemonize, :type => :boolean, :default => false, :desc => "Run as daemon", :aliases=>"-d"
    end
    
    desc "process_once", "run the leaderbeerd processor once"
    standard_options
    processor_options
    def process_once
      process_options
      
      check_pid_and_fork do      
        _process
      end
    end

    desc "process", "run the leaderbeerd processor continuously"
    standard_options
    processor_options
    method_option :frequency, :type => :numeric, :default => 15, :desc => "Delay between runs, in minutes"
    def process
      process_options

      check_pid_and_fork do
        while true
          _process
          ::Leaderbeerd::Config.logger.info "Sleeping for #{options[:frequency]} minutes."
          sleep(options[:frequency] * 60)
        end
      end
    end

  
    desc "server", "start the http server"
    standard_options
    def server
      process_options

      ::Leaderbeerd::Config.logger.info "Starting Sinatra server"
      ::Leaderbeerd::Server.run!
    end
    
    desc "console", "Run a console in the given context"
    standard_options
    def console
      process_options
      ARGV.clear
      IRB.start
    end
    
    private
    def _process
      ::Leaderbeerd::Config.logger.info "Processing..."

      processor = ::Leaderbeerd::Processor.new
      time = Benchmark.realtime do
        processor.process
      end
    
      ::Leaderbeerd::Config.logger.info "Processing completed in #{time}s"      
    end
    
    def process_options
      ::Leaderbeerd::Config.untappd_client_id = options[:untappd_client_id]
      ::Leaderbeerd::Config.untappd_secret = options[:untappd_secret]
      ::Leaderbeerd::Config.untappd_access_token = options[:untappd_access_token]
      ::Leaderbeerd::Config.untappd_usernames = options[:untappd_usernames]
      ::Leaderbeerd::Config.aws_key = options[:aws_key]
      ::Leaderbeerd::Config.aws_secret = options[:aws_secret]
      
      begin
        Dir.mkdir(File.dirname(options[:log_file]))
      rescue SystemCallError
        #suppress mkdir error
      end
      
      ::Leaderbeerd::Config.logger = Logger.new(options[:log_file])
      ::Leaderbeerd::Config.logger.level = Logger.const_get(options[:log_level].upcase)
    end
    
    def check_pid_and_fork
      kill = options.force?
      daemonize = options.daemonize?
      pid_file = options[:pid_file]

      begin
        pid = File.read(pid_file).strip.to_i        
        Process.kill 0, pid
        
        #process exists
        if kill
          ::Leaderbeerd::Config.logger.info "Killing process #{pid}"
          Process.kill "KILL", pid
          sleep(5)
        else
          raise "A Leaderbeerd process is already running with pid of #{pid}.  Run with -f to force a restart."
        end
      rescue Errno::ESRCH, Errno::ENOENT
        ::Leaderbeerd::Config.logger.debug "No pid file found: #{$!}"
        #if the process doesn't exist, keep on trucking
      end

      if daemonize
        Process.fork {
          File.open(pid_file, 'w') {|f| f << Process.pid }
          yield
        }
      else
        yield
      end
      
    end
  end
end