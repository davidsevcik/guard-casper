require 'scenario_helper'

describe Guard::Casper::Util do
  let(:util) { Class.new { extend Guard::Casper::Util } }

  describe '.runner_available?' do
    context 'with the Casper runner available' do
      let(:http) { mock('http') }

      before do
        http.stub_chain(:request, :code).and_return 200
        Net::HTTP.stub(:start).and_yield http
      end

      it 'does show that the runner is available' do
        Guard::Casper::Formatter.should_receive(:info).with "Waiting for Casper test runner at http://localhost:8888/casper"
        util.runner_available?('http://localhost:8888/casper')
      end
    end

    context 'without the Casper runner available' do
      let(:http) { mock('http') }

      context 'because the connection is refused' do
        before do
          Net::HTTP.stub(:start).and_raise Errno::ECONNREFUSED
        end

        it 'does show that the runner is not available' do
          Guard::Casper::Formatter.should_receive(:error).with "Casper test runner isn't available: Connection refused"
          util.runner_available?('http://localhost:8888/casper')
        end
      end

      context 'because the http status is not OK' do
        before do
          http.stub_chain(:request, :code).and_return 404
          Net::HTTP.stub(:start).and_yield http
        end

        it 'does show that the runner is not available' do
          Guard::Casper::Formatter.should_receive(:error).with "Casper test runner fails with response code 404"
          util.runner_available?('http://localhost:8888/casper')
        end
      end

      context 'because a timeout occurs' do
        before do
          Timeout.stub(:timeout).and_raise Timeout::Error
        end

        it 'does show that the runner is not available' do
          Guard::Casper::Formatter.should_receive(:error).with "Timeout waiting for the Casper test runner."
          util.runner_available?('http://localhost:8888/casper')
        end

      end
    end
  end

  describe '.casperjs_bin_valid?' do
    context 'without a casperjs bin' do
      it 'shows a message that the executable is missing' do
        Guard::Casper::Formatter.should_receive(:error).with "CasperJS executable couldn't be auto detected."
        util.casperjs_bin_valid?(nil)
      end
    end

    context 'with a missing CasperJS executable' do
      before do
        util.stub(:`).and_return nil
      end

      it 'shows a message that the executable is missing' do
        Guard::Casper::Formatter.should_receive(:error).with "CasperJS executable doesn't exist at /usr/bin/casperjs"
        util.casperjs_bin_valid?('/usr/bin/casperjs')
      end
    end

    context 'with a something other than a valid CasperJS version' do
      before do
        util.stub(:`).and_return 'Command not found'
      end

      it 'shows a message that the version is wrong' do
        Guard::Casper::Formatter.should_receive(:error).with "CasperJS reports unknown version format: Command not found"
        util.casperjs_bin_valid?('/usr/bin/casperjs')
      end
    end

    context 'with a wrong CasperJS version' do
      before do
        util.stub(:`).and_return '1.1.0'
      end

      it 'shows a message that the version is wrong' do
        Guard::Casper::Formatter.should_receive(:error).with "CasperJS executable at /usr/bin/casperjs must be at least version 1.3.0"
        util.casperjs_bin_valid?('/usr/bin/casperjs')
      end
    end
  end

end
