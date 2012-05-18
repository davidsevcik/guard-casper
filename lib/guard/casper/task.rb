#!/usr/bin/env ruby

require 'rake'
require 'rake/tasklib'

require 'guard/casper/cli'

module Guard

  # Provides a method to define a Rake task that
  # runs the Casper scenarios.
  #
  class CasperTask < ::Rake::TaskLib

    # Name of the main, top level task
    attr_accessor :name

    # CLI options
    attr_accessor :options

    # Initialize the Rake task
    #
    # @param [Symbol] name the name of the Rake task
    # @param [String] options the CLI options
    # @yield [CasperTask] the task
    #
    def initialize(name = :casper, options = '')
      @name = name
      @options = options

      yield self if block_given?

      namespace :guard do
        desc 'Run all Casper scenarios'
        task(name) do
          begin
            # ::Guard::Casper::CLI.start(self.options.split)

          rescue SystemExit => e
            case e.status
            when 1
              fail 'Some scenarios have failed'
            when 2
              fail "The scenario couldn't be run: #{ e.message }'"
            end
          end
        end
      end
    end

  end
end
