require 'scenario_helper'

describe Guard::Casper do

  let(:guard) { Guard::Casper.new }

  let(:runner) { Guard::Casper::Runner }
  let(:formatter) { Guard::Casper::Formatter }
  let(:server) { Guard::Casper::Server }

  let(:defaults) { Guard::Casper::DEFAULT_OPTIONS }

  before do
    runner.stub(:run).and_return [true, []]
    formatter.stub(:notify)
    server.stub(:start)
    server.stub(:stop)
    Guard::Casper.stub(:which).and_return '/usr/local/bin/casperjs'
  end

  describe '#initialize' do
    context 'when no options are provided' do
      it 'sets a default :server option' do
        guard.options[:server].should eql :auto
      end

      it 'sets a default :server option' do
        guard.options[:server_env].should eql 'development'
      end

      it 'sets a default :port option' do
        guard.options[:port].should eql 8888
      end

      it 'sets a default :test_base_url option' do
        guard.options[:test_base_url].should eql 'http://localhost:8888/casper'
      end

      it 'sets a default :timeout option' do
        guard.options[:timeout].should eql 10000
      end

      it 'sets a default :scenario_dir option' do
        guard.options[:scenario_dir].should eql 'scenario/javascripts'
      end

      it 'sets a default :all_on_start option' do
        guard.options[:all_on_start].should be_true
      end

      it 'sets a default :notifications option' do
        guard.options[:notification].should be_true
      end

      it 'sets a default :hide_success option' do
        guard.options[:hide_success].should be_false
      end

      it 'sets a default :max_error_notify option' do
        guard.options[:max_error_notify].should eql 3
      end

      it 'sets a default :keep_failed option' do
        guard.options[:keep_failed].should be_true
      end

      it 'sets a default :all_after_pass option' do
        guard.options[:all_after_pass].should be_true
      end

      it 'sets a default :scenariodoc option' do
        guard.options[:scenariodoc].should eql :failure
      end

      it 'sets a default :console option' do
        guard.options[:console].should eql :failure
      end

      it 'sets a default :errors option' do
        guard.options[:errors].should eql :failure
      end

      it 'sets a default :focus option' do
        guard.options[:focus].should eql true
      end

      it 'sets last run failed to false' do
        guard.last_run_failed.should be_false
      end

      it 'sets last failed paths to empty' do
        guard.last_failed_paths.should be_empty
      end

      it 'tries to auto detect the :casperjs_bin' do
        ::Guard::Casper.should_receive(:which).and_return '/bin/casperjs'
        guard.options[:casperjs_bin].should eql '/bin/casperjs'
      end
    end

    context 'with other options than the default ones' do
      let(:guard) { Guard::Casper.new(nil, { :server           => :casper_gem,
                                              :server_env       => 'test',
                                              :port             => 4321,
                                              :test_base_url      => 'http://192.168.1.5/casper',
                                              :casperjs_bin    => '~/bin/casperjs',
                                              :timeout          => 20000,
                                              :scenario_dir         => 'scenario',
                                              :all_on_start     => false,
                                              :notification     => false,
                                              :max_error_notify => 5,
                                              :hide_success     => true,
                                              :keep_failed      => false,
                                              :all_after_pass   => false,
                                              :scenariodoc          => :always,
                                              :focus            => false,
                                              :errors           => :always,
                                              :console          => :always }) }

      it 'sets the :server option' do
        guard.options[:server].should eql :casper_gem
      end

      it 'sets the :server_env option' do
        guard.options[:server_env].should eql 'test'
      end

      it 'sets the :test_base_url option' do
        guard.options[:port].should eql 4321
      end

      it 'sets the :test_base_url option' do
        guard.options[:test_base_url].should eql 'http://192.168.1.5/casper'
      end

      it 'sets the :casperjs_bin option' do
        guard.options[:casperjs_bin].should eql '~/bin/casperjs'
      end

      it 'sets the :casperjs_bin option' do
        guard.options[:timeout].should eql 20000
      end

      it 'sets the :scenario_dir option' do
        guard.options[:scenario_dir].should eql 'scenario'
      end

      it 'sets the :all_on_start option' do
        guard.options[:all_on_start].should be_false
      end

      it 'sets the :notifications option' do
        guard.options[:notification].should be_false
      end

      it 'sets the :hide_success option' do
        guard.options[:hide_success].should be_true
      end

      it 'sets the :max_error_notify option' do
        guard.options[:max_error_notify].should eql 5
      end

      it 'sets the :keep_failed option' do
        guard.options[:keep_failed].should be_false
      end

      it 'sets the :all_after_pass option' do
        guard.options[:all_after_pass].should be_false
      end

      it 'sets the :scenariodoc option' do
        guard.options[:scenariodoc].should eql :always
      end

      it 'sets the :console option' do
        guard.options[:console].should eql :always
      end

      it 'sets the :errors option' do
        guard.options[:errors].should eql :always
      end

      it 'sets the :focus option' do
        guard.options[:focus].should eql false
      end

    end

    context 'with a port but no test_base_url option set' do
      let(:guard) { Guard::Casper.new(nil, { :port => 4321 }) }

      it 'sets the port on the test_base_url' do
        guard.options[:test_base_url].should eql 'http://localhost:4321/casper'
      end
    end

    context 'with illegal options' do
      let(:guard) { Guard::Casper.new(nil, defaults.merge({ :scenariodoc => :wrong, :server => :unknown })) }

      it 'sets default :scenariodoc option' do
        guard.options[:scenariodoc].should eql :failure
      end
    end
  end

  describe '.start' do
    context 'without a valid CasperJS executable' do

      before do
        Guard::Casper.stub(:casperjs_bin_valid?).and_return false
      end

      it 'throws :task_has_failed' do
        expect { guard.start }.to throw_symbol :task_has_failed
      end
    end

    context 'with a valid CasperJS executable' do
      let(:guard) { Guard::Casper.new(nil, { :casperjs_bin => '/bin/casperjs' }) }

      before do
        ::Guard::Casper.stub(:casperjs_bin_valid?).and_return true
      end

      context 'with the server set to :none' do
        before { guard.options[:server] = :none }

        it 'does not start a server' do
          server.should_not_receive(:start)
          guard.start
        end
      end

      context 'with the server set to something other than :none' do
        before do
          guard.options[:server]     = :casper_gem
          guard.options[:server_env] = 'test'
          guard.options[:port]       = 3333
        end

        it 'does start a server' do
          server.should_receive(:start).with(:casper_gem, 3333, 'test', 'scenario/javascripts')
          guard.start
        end
      end

      context 'with :all_on_start set to true' do
        let(:guard) { Guard::Casper.new(nil, { :all_on_start => true }) }

        context 'with the Casper runner available' do
          before do
            ::Guard::Casper.stub(:runner_available?).and_return true
          end

          it 'triggers .run_all' do
            guard.should_receive(:run_all)
            guard.start
          end
        end

        context 'without the Casper runner available' do
          before do
            ::Guard::Casper.stub(:runner_available?).and_return false
          end

          it 'does not triggers .run_all' do
            guard.should_not_receive(:run_all)
            guard.start
          end
        end
      end

      context 'with :all_on_start set to false' do
        let(:guard) { Guard::Casper.new(nil, { :all_on_start => false }) }

        before do
          ::Guard::Casper.stub(:runner_available?).and_return true
        end

        it 'does not trigger .run_all' do
          guard.should_not_receive(:run_all)
          guard.start
        end
      end
    end
  end

  describe '.stop' do
    context 'with a configured server' do
      let(:guard) { Guard::Casper.new(nil, { :server => :thin }) }

      it 'stops the server' do
        server.should_receive(:stop)
        guard.stop
      end
    end

    context 'without a configured server' do
      let(:guard) { Guard::Casper.new(nil, { :server => :none }) }

      it 'does not stop the server' do
        server.should_not_receive(:stop)
        guard.stop
      end
    end
  end

  describe '.reload' do
    before do
      guard.last_run_failed   = true
      guard.last_failed_paths = ['scenario/javascripts/a.js.coffee']
    end

    it 'sets last run failed to false' do
      guard.reload
      guard.last_run_failed.should be_false
    end

    it 'sets last failed paths to empty' do
      guard.reload
      guard.last_failed_paths.should be_empty
    end
  end

  describe '.run_all' do
    let(:options) { defaults.merge({ :casperjs_bin => '/bin/casperjs' }) }
    let(:guard) { Guard::Casper.new(nil, options) }

    context 'without a scenarioified scenario dir' do
      it 'starts the Runner with the default scenario dir' do
        runner.should_receive(:run).with(['scenario/javascripts'], options).and_return [['scenario/javascripts/a.js.coffee'], true]

        guard.run_all
      end
    end

    context 'with a scenarioified scenario dir' do
      let(:options) { defaults.merge({ :casperjs_bin => '/bin/casperjs', :scenario_dir => 'scenarios' }) }
      let(:guard) { Guard::Casper.new(nil, options) }

      it 'starts the Runner with the default scenario dir' do
        runner.should_receive(:run).with(['scenarios'], options).and_return [['scenario/javascripts/a.js.coffee'], true]

        guard.run_all
      end
    end

    context 'with all scenarios passing' do
      before do
        guard.last_failed_paths = ['scenario/javascripts/a.js.coffee']
        guard.last_run_failed   = true
        runner.stub(:run).and_return [true, []]
      end

      it 'sets the last run failed to false' do
        guard.run_all
        guard.last_run_failed.should be_false
      end

      it 'clears the list of failed paths' do
        guard.run_all
        guard.last_failed_paths.should be_empty
      end
    end

    context 'with failing scenarios' do
      before do
        runner.stub(:run).and_return [false, []]
      end

      it 'throws :task_has_failed' do
        expect { guard.run_all }.to throw_symbol :task_has_failed
      end
    end

  end

  describe '.run_on_change' do
    let(:options) { defaults.merge({ :casperjs_bin => '/Users/michi/.bin/casperjs' }) }
    let(:guard) { Guard::Casper.new(nil, options) }

    it 'returns false when no valid paths are passed' do
      guard.run_on_change(['scenario/javascripts/b.js.coffee'])
    end

    it 'starts the Runner with the cleaned files' do
      runner.should_receive(:run).with(['scenario/javascripts/a.js.coffee'], options).and_return [['scenario/javascripts/a.js.coffee'], true]

      guard.run_on_change(['scenario/javascripts/a.js.coffee', 'scenario/javascripts/b.js.coffee'])
    end

    context 'with :keep_failed enabled' do
      let(:options) { defaults.merge({ :keep_failed => true, :casperjs_bin => '/usr/bin/casperjs' }) }
      let(:guard) { Guard::Casper.new(nil, options) }

      before do
        guard.last_failed_paths = ['scenario/javascripts/b.js.coffee']
      end

      it 'appends the last failed paths to the current run' do
        runner.should_receive(:run).with(['scenario/javascripts/a.js.coffee',
                                          'scenario/javascripts/b.js.coffee'], options)

        guard.run_on_change(['scenario/javascripts/a.js.coffee'])
      end
    end

    context 'with only success scenarios' do
      before do
        guard.last_failed_paths = ['scenario/javascripts/a.js.coffee']
        guard.last_run_failed   = true
        runner.stub(:run).and_return [true, []]
      end

      it 'sets the last run failed to false' do
        guard.run_on_change(['scenario/javascripts/a.js.coffee'])
        guard.last_run_failed.should be_false
      end

      it 'removes the passed scenarios from the list of failed paths' do
        guard.run_on_change(['scenario/javascripts/a.js.coffee'])
        guard.last_failed_paths.should be_empty
      end

      context 'when :all_after_pass is enabled' do
        let(:guard) { Guard::Casper.new(nil, { :all_after_pass => true }) }

        it 'runs all scenarios' do
          guard.should_receive(:run_all)
          guard.run_on_change(['scenario/javascripts/a.js.coffee'])
        end
      end

      context 'when :all_after_pass is enabled' do
        let(:guard) { Guard::Casper.new(nil, { :all_after_pass => false }) }

        it 'does not run all scenarios' do
          guard.should_not_receive(:run_all)
          guard.run_on_change(['scenario/javascripts/a.js.coffee'])
        end
      end
    end

    context 'with failing scenarios' do
      before do
        guard.last_run_failed = false
        runner.stub(:run).and_return [false, ['scenario/javascripts/a.js.coffee']]
      end

      it 'throws :task_has_failed' do
        expect { guard.run_on_change(['scenario/javascripts/a.js.coffee']) }.to throw_symbol :task_has_failed
      end

      it 'sets the last run failed to true' do
        expect { guard.run_on_change(['scenario/javascripts/a.js.coffee']) }.to throw_symbol :task_has_failed
        guard.last_run_failed.should be_true
      end

      it 'appends the failed scenario to the list of failed paths' do
        expect { guard.run_on_change(['scenario/javascripts/a.js.coffee']) }.to throw_symbol :task_has_failed
        guard.last_failed_paths.should =~ ['scenario/javascripts/a.js.coffee']
      end
    end

  end
end
