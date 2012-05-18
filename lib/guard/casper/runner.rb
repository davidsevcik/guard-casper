# coding: utf-8

require 'multi_json'

module Guard
  class Casper

    # The Casper runner handles the execution of the scenario through the CasperJS binary,
    # evaluates the JSON response from the CasperJS Script `guard_casper.coffee`,
    # writes the result to the console and triggers optional system notifications.
    #
    module Runner
      class << self

        # Run the supplied scenarios.
        #
        # @param [Array<String>] paths the scenario files or directories
        # @param [Hash] options the options for the execution
        # @option options [String] :test_base_url the url of the Casper test runner
        # @option options [String] :casperjs_bin the location of the CasperJS binary
        # @option options [Integer] :timeout the maximum time in milliseconds to wait for the scenario runner to finish
        # @option options [String] :scenario_dir the directory with the Casper scenarios
        # @option options [Boolean] :notification show notifications
        # @option options [Boolean] :hide_success hide success message notification
        # @option options [Integer] :max_error_notify maximum error notifications to show
        # @option options [Symbol] :scenariodoc options for the scenariodoc output, either :always, :never
        # @option options [Symbol] :console options for the console.log output, either :always, :never or :failure
        # @option options [String] :scenario_dir the directory with the Casper scenarios
        # @return [Boolean, Array<String>] the status of the run and the failed files
        #
        def run(paths, options = { })
          return [false, []] if paths.empty?

          if paths == options[:scenario_dir]
            paths = Dir.glob("#{ options[:scenario_dir] }/*.js")
            paths += Dir.glob("#{ options[:scenario_dir] }/*.coffee")
          end
          
          paths = paths.uniq
          notify_start_message(paths, options)

          results = paths.inject([]) do |results, file|
            results << evaluate_response(run_casper_scenario(file, options), file, options)

            results
          end.compact

          [response_status_for(results), failed_paths_from(results)]
        end

        private

        # Shows a notification in the console that the runner starts.
        #
        # @param [Array<String>] paths the scenario files or directories
        # @param [Hash] options the options for the execution
        # @option options [String] :scenario_dir the directory with the Casper scenarios
        #
        def notify_start_message(paths, options)
          Formatter.info("Run Casper scenario#{ paths.size == 1 ? '' : 's' } #{ paths.join(' ') }", :reset => true)
        end

        # Returns the failed scenario file names.
        #
        # @param [Array<Object>] results the scenario runner results
        # @return [Array<String>] the list of failed scenario files
        #
        def failed_paths_from(results)
          results.map { |r| !r['passed'] ? r['file'] : nil }.compact
        end

        # Returns the response status for the given result set.
        #
        # @param [Array<Object>] results the scenario runner results
        # @return [Boolean] whether it has passed or not
        #
        def response_status_for(results)
          results.none? { |r| r.has_key?('error') || !r['passed'] }
        end

        # Run the Casper scenario by executing the CasperJS script.
        #
        # @param [String] file with the scenario
        # @param [String] path against which scenario will be run
        # @param [Hash] options the options for the execution
        # @option options [Integer] :timeout the maximum time in milliseconds to wait for the scenario runner to finish
        #
        def run_casper_scenario(file, test_path, options)
          Formatter.info("Run Casper scenario in #{ file }")
          IO.popen("#{ options[:casperjs_bin] } \"#{ file }\" --url=\"#{ options[:test_base_url] }/#{ test_path }\"")
        end

        
        # Evaluates the JSON response that the CasperJS script
        # writes to stdout. The results triggers further notification
        # actions.
        #
        # @param [String] output the JSON output the scenario run
        # @param [String] file the file name of the scenario
        # @param [Hash] options the options for the execution
        # @return [Hash] the suite result
        #
        def evaluate_response(output, file, options)
          # json = output.read
          # 
          # begin
          #   result = MultiJson.decode(json)
          # 
          #   if result['error']
          #     notify_runtime_error(result, options)
          #   else
          #     result['file'] = file
          #     notify_scenario_result(result, options)
          #   end
          # 
          #   result
          # 
          # rescue => e
          #   if json == ''
          #     Formatter.error("No response from the Casper runner!")
          #   else
          #     Formatter.error("Cannot decode JSON from CasperJS runner: #{ e.message }")
          #     Formatter.error('Please report an issue at: https://github.com/netzpirat/guard-casper/issues')
          #     Formatter.error("JSON response: #{ json }")
          #   end
          # ensure
          #   output.close
          # end
          result = output.read
          output.close
          result
        end

        # # Notification when a system error happens that
        # # prohibits the execution of the Casper scenario.
        # #
        # # @param [Hash] the suite result
        # # @param [Hash] options the options for the execution
        # # @option options [Boolean] :notification show notifications
        # #
        # def notify_runtime_error(result, options)
        #   message = "An error occurred: #{ result['error'] }"
        #   Formatter.error(message)
        #   Formatter.notify(message, :title => 'Casper error', :image => :failed, :priority => 2) if options[:notification]
        # end
        # 
        # # Notification about a scenario run, success or failure,
        # # and some stats.
        # #
        # # @param [Hash] result the suite result
        # # @param [Hash] options the options for the execution
        # # @option options [Boolean] :notification show notifications
        # # @option options [Boolean] :hide_success hide success message notification
        # #
        # def notify_scenario_result(result, options)
        #   scenarios           = result['stats']['scenarios']
        #   failures        = result['stats']['failures']
        #   time            = result['stats']['time']
        #   scenarios_plural    = scenarios == 1    ? '' : 's'
        #   failures_plural = failures == 1 ? '' : 's'
        #   
        #   Formatter.info("\nFinished in #{ time } seconds")
        #   
        #   message      = "#{ scenarios } scenario#{ scenarios_plural }, #{ failures } failure#{ failures_plural }"
        #   full_message = "#{ message }\nin #{ time } seconds"
        #   passed       = failures == 0
        #   
        #   if passed
        #     report_scenariodoc(result, passed, options) if options[:scenariodoc] == :always
        #     Formatter.success(message)
        #     Formatter.notify(full_message, :title => 'Casper suite passed') if options[:notification] && !options[:hide_success]
        #   else
        #     report_scenariodoc(result, passed, options) if options[:scenariodoc] != :never
        #     Formatter.error(message)
        #     notify_errors(result, options)
        #     Formatter.notify(full_message, :title => 'Casper suite failed', :image => :failed, :priority => 2) if options[:notification]
        #   end
        #   
        #   Formatter.info("Done.\n")
        # end
        # 
        # # Specdoc like formatting of the result.
        # #
        # # @param [Hash] result the suite result
        # # @param [Boolean] passed status
        # # @param [Hash] options the options
        # # @option options [Symbol] :console options for the console.log output, either :always, :never or :failure
        # #
        # def report_scenariodoc(result, passed, options)
        #   result['suites'].each do |suite|
        #     report_scenariodoc_suite(suite, passed, options)
        #   end
        # end
        # 
        # # Show the suite result.
        # #
        # # @param [Hash] suite the suite
        # # @param [Boolean] passed status
        # # @param [Hash] options the options
        # # @option options [Symbol] :console options for the console.log output, either :always, :never or :failure
        # # @option options [Symbol] :focus options for focus on failures in the scenariodoc
        # # @param [Number] level the indention level
        # #
        # def report_scenariodoc_suite(suite, passed, options, level = 0)
        #   Formatter.suite_name((' ' * level) + suite['description']) if passed || options[:focus] && contains_failed_scenario?(suite)
        # 
        #   suite['scenarios'].each do |scenario|
        #     if scenario['passed']
        #       if passed || !options[:focus]
        #         Formatter.success(indent("  ✔ #{ scenario['description'] }", level))
        #         report_scenariodoc_logs(scenario, options, level)
        #       end
        #     else
        #       Formatter.scenario_failed(indent("  ✘ #{ scenario['description'] }", level))
        #       scenario['messages'].each do |message|
        #         Formatter.scenario_failed(indent("    ➤ #{ format_message(message, false) }", level))
        #       end
        #       report_scenariodoc_errors(scenario, options, level)
        #       report_scenariodoc_logs(scenario, options, level)
        #     end
        #   end
        # 
        #   suite['suites'].each { |suite| report_scenariodoc_suite(suite, passed, options, level + 2) } if suite['suites']
        # end
        # 
        # # Shows the logs for a given scenario.
        # #
        # # @param [Hash] scenario the scenario result
        # # @param [Hash] options the options
        # # @option options [Symbol] :console options for the console.log output, either :always, :never or :failure
        # # @param [Number] level the indention level
        # #
        # def report_scenariodoc_logs(scenario, options, level)
        #   if scenario['logs'] && (options[:console] == :always || (options[:console] == :failure && !scenario['passed']))
        #     scenario['logs'].each do |log|
        #       log.split("\n").each_with_index do |message, index|
        #         Formatter.info(indent("    #{ index == 0 ? '•' : ' ' } #{ message }", level))
        #       end
        #     end
        #   end
        # end
        # 
        # # Shows the errors for a given scenario.
        # #
        # # @param [Hash] scenario the scenario result
        # # @param [Hash] options the options
        # # @option options [Symbol] :errors options for the errors output, either :always, :never or :failure
        # # @param [Number] level the indention level
        # #
        # def report_scenariodoc_errors(scenario, options, level)
        #   if scenario['errors'] && (options[:errors] == :always || (options[:errors] == :failure && !scenario['passed']))
        #     scenario['errors'].each do |error|
        #       if error['trace']
        #         Formatter.scenario_failed(indent("    ➜ Exception: #{ error['msg']  } in #{ error['trace']['file'] } on line #{ error['trace']['line'] }", level))
        #       else
        #         Formatter.scenario_failed(indent("    ➜ Exception: #{ error['msg']  }", level))
        #       end
        #     end
        #   end
        # end
        # 
        # # Indent a message.
        # #
        # # @param [String] message the message
        # # @param [Number] level the indention level
        # #
        # def indent(message, level)
        #   (' ' * level) + message
        # end
        # 
        # # Show system notifications about the occurred errors.
        # #
        # # @param [Hash] result the suite result
        # # @param [Hash] options the options
        # # @option options [Integer] :max_error_notify maximum error notifications to show
        # # @option options [Boolean] :notification show notifications
        # #
        # def notify_errors(result, options)
        #   collect_scenarios(result['suites']).each_with_index do |scenario, index|
        #     if !scenario['passed'] && options[:max_error_notify] > index
        #       msg = scenario['messages'].map { |message| format_message(message, true) }.join(', ')
        #       Formatter.notify("#{ scenario['description'] }: #{ msg }",
        #                        :title    => 'Casper scenario failed',
        #                        :image    => :failed,
        #                        :priority => 2) if options[:notification]
        #     end
        #   end
        # end
        # 
        # # Tests if the given suite has a failing scenario underneath.
        # #
        # # @param [Hash] suite the suite result
        # # @return [Boolean] the search result
        # #
        # def contains_failed_scenario?(suite)
        #   collect_scenarios([suite]).any? { |scenario| !scenario['passed'] }
        # end
        # 
        # # Get all scenarios from the suites and its nested suites.
        # #
        # # @param suites [Array<Hash>] the suites results
        # # @param [Array<Hash>] all scenarios
        # #
        # def collect_scenarios(suites)
        #   suites.inject([]) do |scenarios, suite|
        #     scenarios = (scenarios | suite['scenarios']) if suite['scenarios']
        #     scenarios = (scenarios | collect_scenarios(suite['suites'])) if suite['suites']
        #     scenarios
        #   end
        # end
        # 
        # # Formats a message.
        # #
        # # @param [String] message the error message
        # # @param [Boolean] short show a short version of the message
        # # @return [String] the cleaned error message
        # #
        # def format_message(message, short)
        #   if message =~ /(.*?) in http.+?assets\/(.*)\?body=\d+\s\((line\s\d+)/
        #     short ? $1 : "#{ $1 } in #{ $2 } on #{ $3 }"
        #   else
        #     message
        #   end
        # end

      end
    end
  end
end
