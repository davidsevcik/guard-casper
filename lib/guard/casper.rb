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
        :port             => 7777,
        :test_base_url    => 'http://localhost:7777/test',
        :timeout          => 10000,
        :scenario_dir     => 'scenario',
        :notification     => true,
        :hide_success     => false,
        :all_on_start     => true,
        :keep_failed      => true,
        :all_after_pass   => true,
        :max_error_notify => 3,
        :scenariodoc      => :failure,
        :console          => :failure,
        :errors           => :failure,
        :focus            => true
    }

    # Initialize Guard::Casper.
    #
    # @param [Array<Guard::Watcher>] watchers the watchers in the Guard block
    # @param [Hash] options the options for the Guard
    # @option options [String] :server the server to use, either :auto, :none, :webrick, :mongrel, :thin, :casper_gem, or a custom rake task
    # @option options [String] :server_env the server environment to use, for example :development, :test
    # @option options [String] :port the port for the Casper test server
    # @option options [String] :test_base_url the base url against the tests will be run
    # @option options [String] :casperjs_bin the location of the CasperJS binary
    # @option options [Integer] :timeout the maximum time in milliseconds to wait for the scenario runner to finish
    # @option options [String] :scenario_dir the directory with the Casper scenarios
    # @option options [Boolean] :notification show notifications
    # @option options [Boolean] :hide_success hide success message notification
    # @option options [Integer] :max_error_notify maximum error notifications to show
    # @option options [Boolean] :all_on_start run all suites on start
    # @option options [Boolean] :keep_failed keep failed suites and add them to the next run again
    # @option options [Boolean] :clean clean the scenarios according to rails naming conventions
    # @option options [Boolean] :all_after_pass run all suites after a suite has passed again after failing
    # @option options [Symbol] :scenariodoc options for the scenariodoc output, either :always, :never or :failure
    # @option options [Symbol] :console options for the console.log output, either :always, :never or :failure
    # @option options [Symbol] :errors options for the errors output, either :always, :never or :failure
    # @option options [Symbol] :focus options for focus on failures in the scenariodoc
    #
    def initialize(watchers = [], options = { })
      options[:test_base_url] = "http://localhost:#{ options[:port] }/test" if options[:port] && !options[:test_base_url]
      options = DEFAULT_OPTIONS.merge(options)
      options[:scenariodoc] = :failure if ![:always, :never, :failure].include? options[:scenariodoc]
      options[:server] ||= :auto
      options[:casperjs_bin] = Casper.which('casperjs') unless options[:casperjs_bin]

      super(watchers, options)

      self.last_run_failed   = false
      self.last_failed_paths = []
    end

    # Gets called once when Guard starts.
    #
    # @raise [:task_has_failed] when run_on_change has failed
    #
    def start
      if Casper.casperjs_bin_valid?(options[:casperjs_bin])

        Server.start(options[:server], options[:port], options[:server_env], options[:scenario_dir]) unless options[:server] == :none

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

    # Gets called when the Guard should reload itself.
    #
    # @raise [:task_has_failed] when run_on_change has failed
    #
    def reload
      self.last_run_failed   = false
      self.last_failed_paths = []
    end

    # Gets called when all scenarios should be run.
    #
    # @raise [:task_has_failed] when run_on_change has failed
    #
    def run_all
      passed, failed_scenarios = Runner.run(options[:scenarios] || [options[:scenario_dir]], options)

      self.last_failed_paths = failed_scenarios
      self.last_run_failed   = !passed

      throw :task_has_failed unless passed
    end

    # Gets called when watched paths and files have changes.
    #
    # @param [Array<String>] paths the changed paths and files
    # @raise [:task_has_failed] when run_on_change has failed
    #
    def run_on_change(paths)
      scenarios = options[:keep_failed] ? paths + self.last_failed_paths : paths
      return false if scenarios.empty?

      passed, failed_scenarios = Runner.run(scenarios, options)

      if passed
        self.last_failed_paths = self.last_failed_paths - paths
        run_all if self.last_run_failed && options[:all_after_pass]
      else
        self.last_failed_paths = self.last_failed_paths + failed_scenarios
      end

      self.last_run_failed = !passed

      throw :task_has_failed unless passed
    end

  end
end
