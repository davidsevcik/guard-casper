# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'guard/casper/version'

Gem::Specification.new do |s|
  s.name        = 'guard-casper'
  s.version     = Guard::CasperVersion::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['David Sevcik']
  s.email       = ['david.sevcik@gmail.com']
  s.homepage    = 'https://github.com/davidsevcik/guard-casper'
  s.summary     = 'Guard gem for testing with CasperJS'
  s.description = 'Guard::Casper automatically runs CasperJS test scenarios'

  s.required_rubygems_version = '>= 1.3.6'

  s.add_dependency 'guard', '>= 0.8.3'
  s.add_dependency 'childprocess'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'guard-rscenario'
  s.add_development_dependency 'guard-coffeescript'
  s.add_development_dependency 'guard-shell'
  s.add_development_dependency 'rscenario'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'redcarpet'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'yajl-ruby'

  s.files        = Dir.glob('{bin,lib}/**/*') + %w[README.md]
  s.require_path = 'lib'
end
