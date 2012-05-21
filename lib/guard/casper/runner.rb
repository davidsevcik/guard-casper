# coding: utf-8

module Guard
  class Casper

    # The Casper runner handles the execution of the scenario through the CasperJS binary.
    #
    module Runner
      class << self

        # Run the supplied scenarios.
        #
        # @param [String | Array<String>] paths the scenario files or directories
        # @param [Hash] options the options for the execution
        # @option options [String] :base_url the url of the Casper test runner
        # @option options [String] :casperjs_bin the location of the CasperJS binary
        # @return Boolean the status of the run
        #
        def run(paths, options = { })
          return false if paths.empty?
          paths = [paths] unless paths.is_a? Array

          Formatter.info("Run Casper scenario#{ paths.size == 1 ? '' : 's' } in #{ paths.join(' ') }", :reset => true)
          
          if system "#{ options[:casperjs_bin] } test #{ paths.join(' ') } --base_url=\"#{ options[:base_url] }\""
            
            Formatter.notify(paths.join("\n"), :title => 'Casper scenarios passed')
            return true
          else
            Formatter.notify(paths.join("\n"), :title => 'Casper scenarios failed', :image => :failed, :priority => 2)
            return false
          end
        end
        
      end
    end
  end
end
