require 'net/http'
require 'timeout'
require 'guard/casper/formatter'

module Guard
  class Casper

    # Provider of some shared utility methods.
    #
    module Util

      # Verifies that the casperjs bin is available and the
      # right version is installed.
      #
      # @param [String] bin the location of the casperjs bin
      # @return [Boolean] when the runner is available
      #
      def casperjs_bin_valid?(bin)
        if bin && !bin.empty?
          version = `#{ bin } --version`

          if version
            # Remove all but version, e.g. from '1.5 (development)'
            cleaned_version = version.match(/(\d\.)*(\d)/)

            if cleaned_version
              if Gem::Version.new(cleaned_version[0]) < Gem::Version.new('0.6.6')
                ::Guard::Casper::Formatter.error "CasperJS executable at #{ bin } must be at least version 0.6.6"
              else
                true
              end
            else
              ::Guard::Casper::Formatter.error "CasperJS reports unknown version format: #{ version }"
            end
          else
            ::Guard::Casper::Formatter.error "CasperJS executable doesn't exist at #{ bin }"
          end
        else
          ::Guard::Casper::Formatter.error "CasperJS executable couldn't be auto detected."
        end
      end

      # Cross-platform way of finding an executable in the $PATH.
      # http://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
      #
      # @example
      #   which('ruby') #=> /usr/bin/ruby
      #
      # @param cmd [String] the executable to find
      # @return [String, nil] the path to the executable
      #
      def which(cmd)
        exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']

        ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
          exts.each do |ext|
            exe = "#{ path }/#{ cmd }#{ ext }"
            return exe if File.executable?(exe)
          end
        end

        nil
      end

    end

  end
end
