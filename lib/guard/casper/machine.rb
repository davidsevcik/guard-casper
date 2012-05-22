# coding: utf-8

require 'guard/casper/formatter'
require 'guard/casper/server'
require 'guard/casper/util'


module Guard
  class Casper
      
    class CasperBinError < Exception
    end

    # The Casper runner handles the execution of the scenario through the CasperJS binary.
    #
    class Machine
  
      DEFAULT_OPTIONS = {
        :server           => :auto,
        :server_env       => 'test',
        :port             => 8888,
        :base_url         => 'http://localhost:8888/test',
        :scenario_paths   => ['scenario'],
        :all_on_start     => true,
        :throw_failed     => true,
        :notify           => true,
        :xunit_report     => nil
      }
      
      # Initialize Guard::Casper::Machine.
      #
      # @option options [String] :server the server to use, either :auto, :none, :webrick, :mongrel, :thin, :casper_gem, or a custom rake task
      # @option options [String] :server_env the server environment to use, for example :development, :test
      # @option options [String] :port the port for the Casper test server
      # @option options [String] :base_url the base url against the tests will be run
      # @option options [String] :casperjs_bin the location of the CasperJS binary
      # @option options [String | Array<String>] :scenario_paths paths to Casper scenarios
      # @option options [Boolean] :all_on_start run all suites on start
      def initialize(options = {})
        options[:base_url] = "http://localhost:#{ options[:port] }/test" if options[:port] && !options[:base_url]
        @options = DEFAULT_OPTIONS.merge(options)
        @options[:server] ||= :auto
        @options[:casperjs_bin] = ::Guard::Casper::Util.which('casperjs') unless @options[:casperjs_bin]
      end
      
      
      # Gets called once when Guard starts.
      #
      # @raise [CasperBinError] when problems with casperjs bit occured
      #
      def start
        ::Guard::Casper::Util.assert_casperjs_bin(@options[:casperjs_bin])
        
        if ::Guard::Casper::Util.server_is_running(@options[:base_url])
         @options[:server] = :none
         ::Guard::Casper::Formatter.info("Test server on #{ @options[:base_url] } is already running")
        end

        unless @options[:server] == :none
         ::Guard::Casper::Server.start(@options[:server], @options[:port], @options[:server_env]) 
        end

        run_all if @options[:all_on_start]
      end
      
      
      # Gets called once when Guard stops.
      def stop
        ::Guard::Casper::Server.stop unless @options[:server] == :none
      end
      
      
      # Gets called when all scenarios should be run.
      #
      # @raise [:task_has_failed] when scenarios failed
      #
      def run_all
        run(@options[:scenario_paths])
      end

      

      # Run the supplied scenarios.
      #
      # @param [String | Array<String>] paths the scenario files or directories
      # @return Boolean the status of the run
      #
      def run(paths)
        return false if paths.empty?
        paths = [paths] unless paths.is_a? Array

        ::Guard::Casper::Formatter.info("Run Casper scenario#{ paths.size == 1 ? '' : 's' } in #{ paths.join(' ') }", 
          :reset => true)
        
        args = []
        args << "--base_url=\"#{ @options[:base_url] }\""
        args << "--xunit=\"#{ @options[:xunit_report] }\"" if @options[:xunit_report]
        
        if system "#{ @options[:casperjs_bin] } test #{ paths.join(' ') } #{ args.join(' ') }"
          
          ::Guard::Casper::Formatter.notify(paths.join("\n"), :title => 'Casper scenarios passed') if @options[:notify]
          return true
        else
          ::Guard::Casper::Formatter.notify(paths.join("\n"), :title => 'Casper scenarios failed', 
            :image => :failed, :priority => 2) if @options[:notify]
          return false
        end
      end
        
    end
  end
end
