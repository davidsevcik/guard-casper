require 'net/http'

require 'guard'
require 'guard/guard'
require 'guard/watcher'

module Guard

  # The Casper guard that gets notifications about the following
  # Guard events: `start`, `stop`, `reload`, `run_all` and `run_on_change`.
  #
  class Casper < Guard

    autoload :Runner, 'guard/casper/runner'
    autoload :Server, 'guard/casper/server'
    autoload :Util, 'guard/casper/util'

    extend Util

    attr_accessor :last_run_failed, :last_failed_paths

    DEFAULT_OPTIONS = {
        :server           => :auto,
        :server_env       => 'test',
        :port             => 8888,
        :base_url         => 'http://localhost:8888/test',
        :scenario_paths   => 'scenario',
        :all_on_start     => true,
    }

    # Initialize Guard::Casper.
    #
    # @param [Array<Guard::Watcher>] watchers the watchers in the Guard block
    # @param [Hash] options the options for the Guard
    # @option options [String] :server the server to use, either :auto, :none, :webrick, :mongrel, :thin, :casper_gem, or a custom rake task
    # @option options [String] :server_env the server environment to use, for example :development, :test
    # @option options [String] :port the port for the Casper test server
    # @option options [String] :base_url the base url against the tests will be run
    # @option options [String] :casperjs_bin the location of the CasperJS binary
    # @option options [String | Array<String>] :scenario_paths paths to Casper scenarios
    # @option options [Boolean] :all_on_start run all suites on start
    #
    def initialize(watchers = [], options = { })
      options[:base_url] = "http://localhost:#{ options[:port] }/test" if options[:port] && !options[:base_url]
      options = DEFAULT_OPTIONS.merge(options)
      options[:server] ||= :auto
      options[:casperjs_bin] = Casper.which('casperjs') unless options[:casperjs_bin]

      super(watchers, options)
    end

    # Gets called once when Guard starts.
    #
    # @raise [:task_has_failed] when run_on_change has failed
    #
    def start
      if Casper.casperjs_bin_valid?(options[:casperjs_bin])
        
        if server_is_running(options[:base_url])
          options[:server] = :none
          Formatter.info("Test server on #{options[:base_url]} is already running")
        end
        
        Server.start(options[:server], options[:port], options[:server_env]) unless options[:server] == :none

        run_all if options[:all_on_start]
      else
        throw :task_has_failed
      end
    end

    # Gets called once when Guard stops.
    #
    # @raise [:task_has_failed] when stop has failed
    #
    def stop
      Server.stop unless options[:server] == :none
    end


    # Gets called when all scenarios should be run.
    #
    # @raise [:task_has_failed] when run_on_change has failed
    #
    def run_all
      passed = Runner.run(options[:scenario_paths], options)
      throw :task_has_failed unless passed
    end

    # Gets called when watched paths and files have changes.
    #
    # @param [Array<String>] paths the changed paths and files
    # @raise [:task_has_failed] when run_on_change has failed
    #
    def run_on_change(paths)
      return false if paths.empty?
      passed = Runner.run(paths, options)
      throw :task_has_failed unless passed
    end
    
    
    private
    
    def server_is_running(path)
      Net::HTTP.get_response(URI(path)).is_a? Net::HTTPOK
    rescue
      return false
    end
  end
end
