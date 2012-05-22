require 'net/http'

require 'guard'
require 'guard/guard'
require 'guard/watcher'

module Guard

  # The Casper guard that gets notifications about the following
  # Guard events: `start`, `stop`, `reload`, `run_all` and `run_on_change`.
  #
  class Casper < Guard
    
    autoload :Machine, 'guard/casper/machine'
    autoload :Formatter, 'guard/casper/formatter'
    
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
    def initialize(watchers = [], options = {})
      @machine = Machine.new(options)
      super(watchers, options)
    end

    # Gets called once when Guard starts.
    #
    # @raise [:task_has_failed] when run_on_change has failed
    #
    def start
      @machine.start
    rescue => e
      Formatter.error e.message
      throw :task_has_failed
    end

    # Gets called once when Guard stops.
    def stop
      @machine.stop
    end


    # Gets called when all scenarios should be run.
    #
    # @raise [:task_has_failed] when some scenario failed
    #
    def run_all
      throw :task_has_failed unless @machine.run_all
    end

    # Gets called when watched paths and files have changes.
    #
    # @param [Array<String>] paths the changed paths and files
    # @raise [:task_has_failed] when some scenario failed
    #
    def run_on_change(paths)
      return false if paths.empty?
      throw :task_has_failed unless @machine.run(paths)
    end
  end
end
