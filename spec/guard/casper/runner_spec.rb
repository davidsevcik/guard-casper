# coding: utf-8

require 'scenario_helper'

describe Guard::Casper::Runner do

  let(:runner) { Guard::Casper::Runner }
  let(:formatter) { Guard::Casper::Formatter }

  let(:defaults) { Guard::Casper::DEFAULT_OPTIONS.merge({ :casperjs_bin => '/usr/local/bin/casperjs' }) }

  let(:casperjs_error_response) do
    <<-JSON
    {
      "error": "Cannot request Casper scenarios"
    }
    JSON
  end

  let(:casperjs_failure_response) do
    <<-JSON
    {
      "passed": false,
      "stats": {
        "scenarios": 3,
        "failures": 2,
        "time": 0.007
      },
      "suites": [
        {
          "description": "Failure suite",
          "scenarios": [
            {
              "description": "Failure scenario tests something",
              "messages": [
                "ReferenceError: Can't find variable: a in http://localhost:8888/assets/backbone/models/model_scenario.js?body=1 (line 27)"
              ],
              "logs": [
                "console.log message"
              ],
              "errors": [
                {
                  "msg": "Error message",
                  "trace" : {
                    "file": "/path/to/file.js",
                    "line": "255"
                  }
                }
              ],
              "passed": false
            }
          ],
          "suites": [
            {
              "description": "Nested failure suite",
              "scenarios": [
                {
                  "description": "Failure scenario 2 tests something",
                  "messages": [
                    "ReferenceError: Can't find variable: b in http://localhost:8888/assets/backbone/models/model_scenario.js?body=1 (line 27)"
                  ],
                  "passed": false
                },
                {
                  "description": "Success scenario tests something",
                  "passed": true,
                  "logs": [
                    "Another console.log message",
                    "And even more console.log messages"
                  ],
                  "errors": [
                    {
                      "msg": "Another error message",
                      "trace" : {
                        "file": "/path/to/file.js",
                        "line": "255"
                      }
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    }
    JSON
  end

  let(:casperjs_success_response) do
    <<-JSON
    {
      "passed": true,
      "stats": {
        "scenarios": 3,
        "failures": 0,
        "time": 0.009
      },
      "suites": [
        {
          "description": "Success suite",
          "scenarios": [
            {
              "description": "Success test tests something",
              "passed": true
            },
            {
              "description": "Another success test tests something",
              "passed": true,
              "logs": [
                "I can haz console.logs"
              ]
            }
          ],
          "suites": [
            {
              "description": "Nested success suite",
              "scenarios": [
                {
                  "description": "Success nested test tests something",
                  "passed": true
                }
              ]
            }
          ]
        }
      ]
    }
    JSON
  end

  let(:casperjs_command) do
    "/usr/local/bin/casperjs #{ @project_path }/lib/guard/casper/casperjs/guard-casper.coffee"
  end

  before do
    formatter.stub(:info)
    formatter.stub(:debug)
    formatter.stub(:error)
    formatter.stub(:success)
    formatter.stub(:scenario_failed)
    formatter.stub(:suite_name)
    formatter.stub(:notify)
  end

  describe '#run' do
    before do
      File.stub(:foreach).and_yield 'describe "ErrorTest", ->'
      IO.stub(:popen).and_return StringIO.new(casperjs_error_response)
    end

    context 'when passed an empty paths list' do
      it 'returns false' do
        runner.run([]).should eql [false, []]
      end
    end

    context 'when passed the scenario directory' do
      it 'requests all casper scenarios from the server' do
        IO.should_receive(:popen).with("#{ casperjs_command } \"http://localhost:8888/casper\" 10000 failure true failure failure")
        runner.run(['scenario/javascripts'], defaults.merge({ :notification => false }))
      end

      it 'shows a start information in the console' do
        formatter.should_receive(:info).with('Run all Casper suites', { :reset => true })
        formatter.should_receive(:info).with('Run Casper suite at http://localhost:8888/casper')
        runner.run(['scenario/javascripts'], defaults)
      end
    end

    context 'for an erroneous Casper runner' do
      it 'requests the casper scenarios from the server' do
        IO.should_receive(:popen).with("#{ casperjs_command } \"http://localhost:8888/casper?scenario=ErrorTest\" 10000 failure true failure failure")
        runner.run(['scenario/javascripts/a.js.coffee'], defaults)
      end

      it 'shows the error in the console' do
        formatter.should_receive(:error).with(
            "An error occurred: Cannot request Casper scenarios"
        )
        runner.run(['scenario/javascripts/a.js.coffee'], defaults)
      end

      it 'returns the errors' do
        response = runner.run(['scenario/javascripts/a.js.coffee'], defaults)
        response.first.should be_false
        response.last.should =~ []
      end

      context 'with notifications' do
        it 'shows an error notification' do
          formatter.should_receive(:notify).with(
              "An error occurred: Cannot request Casper scenarios",
              :title    => 'Casper error',
              :image    => :failed,
              :priority => 2
          )
          runner.run(['scenario/javascripts/a.js.coffee'], defaults)
        end
      end

      context 'without notifications' do
        it 'does not shows an error notification' do
          formatter.should_not_receive(:notify)
          runner.run(['scenario/javascripts/a.js.coffee'], defaults.merge({ :notification => false }))
        end
      end
    end

    context "for a failing Casper runner" do
      before do
        File.stub(:foreach).and_yield 'describe "FailureTest", ->'
        IO.stub(:popen).and_return StringIO.new(casperjs_failure_response)
      end

      it 'requests the casper scenarios from the server' do
        File.should_receive(:foreach).with('scenario/javascripts/x/b.js.coffee').and_yield 'describe "FailureTest", ->'
        IO.should_receive(:popen).with("#{ casperjs_command } \"http://localhost:8888/casper?scenario=FailureTest\" 10000 failure true failure failure")
        runner.run(['scenario/javascripts/x/b.js.coffee'], defaults)
      end

      it 'returns the failures' do
        response = runner.run(['scenario/javascripts/x/b.js.coffee'], defaults)
        response.first.should be_false
        response.last.should =~ ['scenario/javascripts/x/b.js.coffee']
      end

      context 'with the scenariodoc set to :never' do
        it 'shows the summary in the console' do
          formatter.should_receive(:info).with(
              'Run Casper suite scenario/javascripts/x/b.js.coffee', { :reset => true }
          )
          formatter.should_receive(:info).with(
              'Run Casper suite at http://localhost:8888/casper?scenario=FailureTest'
          )
          formatter.should_not_receive(:suite_name)
          formatter.should_not_receive(:scenario_failed)
          formatter.should_receive(:error).with(
              "3 scenarios, 2 failures"
          )
          runner.run(['scenario/javascripts/x/b.js.coffee'], defaults.merge({ :scenariodoc => :never }))
        end
      end

      context 'with the scenariodoc set either :always or :failure' do
        it 'shows the failed suites' do
          formatter.should_receive(:suite_name).with(
              'Failure suite'
          )
          formatter.should_receive(:scenario_failed).with(
              '  ✘ Failure scenario tests something'
          )
          formatter.should_receive(:scenario_failed).with(
              "    ➤ ReferenceError: Can't find variable: a in backbone/models/model_scenario.js on line 27"
          )
          formatter.should_receive(:suite_name).with(
              '  Nested failure suite'
          )
          formatter.should_receive(:scenario_failed).with(
              '    ✘ Failure scenario 2 tests something'
          )
          formatter.should_receive(:scenario_failed).with(
              "      ➤ ReferenceError: Can't find variable: b in backbone/models/model_scenario.js on line 27"
          )
          runner.run(['scenario/javascripts/x/b.js.coffee'], defaults.merge({ :console => :always }))
        end

        context 'with focus enabled' do
          it 'does not show the passed scenarios' do
            formatter.should_not_receive(:success).with(
                '    ✔ Success scenario tests something'
            )
            formatter.should_not_receive(:scenario_failed).with(
                "    ➜ Exception: Another error message in /path/to/file.js on line 255"
            )
            formatter.should_not_receive(:info).with(
                "      • Another console.log message"
            )
            formatter.should_not_receive(:info).with(
                "      • And even more console.log messages"
            )
            runner.run(['scenario/javascripts/x/b.js.coffee'], defaults.merge({ :console => :always, :errors => :always, :focus => true }))
          end
        end

        context 'with focus disabled' do
          it 'does show the passed scenarios' do
            formatter.should_receive(:success).with(
                '    ✔ Success scenario tests something'
            )
            formatter.should_receive(:info).with(
                "      • Another console.log message"
            )
            formatter.should_receive(:info).with(
                "      • And even more console.log messages"
            )
            runner.run(['scenario/javascripts/x/b.js.coffee'], defaults.merge({ :console => :always, :focus => false }))
          end
        end

        context 'with console logs set to :always' do
          it 'shows the failed console logs' do
            formatter.should_receive(:info).with(
                "    • console.log message"
            )
            runner.run(['scenario/javascripts/x/b.js.coffee'], defaults.merge({ :console => :always }))
          end
        end

        context 'with error logs set to :always' do
          it 'shows the failed console logs' do
            formatter.should_receive(:scenario_failed).with(
                "    ➜ Exception: Error message in /path/to/file.js on line 255"
            )
            runner.run(['scenario/javascripts/x/b.js.coffee'], defaults.merge({ :errors => :always }))
          end
        end

        context 'with console logs set to :never' do
          it 'does not shows the console logs' do
            formatter.should_not_receive(:info).with(
                "    • console.log message"
            )
            formatter.should_not_receive(:info).with(
                "      • Another console.log message"
            )
            formatter.should_not_receive(:info).with(
                "      • And even more console.log messages"
            )
            runner.run(['scenario/javascripts/x/b.js.coffee'], defaults.merge({ :console => :never }))
          end
        end

        context 'with error logs set to :never' do
          it 'does not shows the console logs' do
            formatter.should_not_receive(:scenario_failed).with(
                "    ➜ Exception: Error message in /path/to/file.js on line 255"
            )
            formatter.should_not_receive(:scenario_failed).with(
                "    ➜ Exception: Another error message in /path/to/file.js on line 255"
            )
            runner.run(['scenario/javascripts/x/b.js.coffee'], defaults.merge({ :errors => :never }))
          end
        end

        context 'with console logs set to :failure' do
          it 'shows the the console logs for failed scenarios' do
            formatter.should_receive(:info).with(
                "    • console.log message"
            )
            formatter.should_not_receive(:info).with(
                "      • Another console.log message"
            )
            formatter.should_not_receive(:info).with(
                "      • And even more console.log messages"
            )
            runner.run(['scenario/javascripts/x/b.js.coffee'], defaults.merge({ :console => :failure }))
          end
        end

        context 'with error logs set to :failure' do
          it 'shows the the console logs for failed scenarios' do
            formatter.should_receive(:scenario_failed).with(
                "    ➜ Exception: Error message in /path/to/file.js on line 255"
            )
            formatter.should_not_receive(:scenario_failed).with(
                "    ➜ Exception: Another error message in /path/to/file.js on line 255"
            )
            runner.run(['scenario/javascripts/x/b.js.coffee'], defaults.merge({ :errors => :failure }))
          end
        end
      end

      context 'with notifications' do
        it 'shows the failing scenario notification' do
          formatter.should_receive(:notify).with(
              "Failure scenario tests something: ReferenceError: Can't find variable: a",
              :title    => 'Casper scenario failed',
              :image    => :failed,
              :priority => 2
          )
          formatter.should_receive(:notify).with(
              "Failure scenario 2 tests something: ReferenceError: Can't find variable: b",
              :title    => 'Casper scenario failed',
              :image    => :failed,
              :priority => 2
          )
          formatter.should_receive(:notify).with(
              "3 scenarios, 2 failures\nin 0.007 seconds",
              :title    => 'Casper suite failed',
              :image    => :failed,
              :priority => 2
          )
          runner.run(['scenario/javascripts/x/b.js.coffee'], defaults)
        end

        context 'with :max_error_notify' do
          it 'shows the failing scenario notification' do
            formatter.should_receive(:notify).with(
                "Failure scenario tests something: ReferenceError: Can't find variable: a",
                :title    => 'Casper scenario failed',
                :image    => :failed,
                :priority => 2
            )
            formatter.should_not_receive(:notify).with(
                "Failure scenario 2 tests something: ReferenceError: Can't find variable: b",
                :title    => 'Casper scenario failed',
                :image    => :failed,
                :priority => 2
            )
            formatter.should_receive(:notify).with(
                "3 scenarios, 2 failures\nin 0.007 seconds",
                :title    => 'Casper suite failed',
                :image    => :failed,
                :priority => 2
            )
            runner.run(['scenario/javascripts/x/b.js.coffee'], defaults.merge({ :max_error_notify => 1 }))
          end
        end

        context 'without notifications' do
          it 'does not show a failure notification' do
            formatter.should_not_receive(:notify)
            runner.run(['scenario/javascripts/x/b.js.coffee'], defaults.merge({ :notification => false }))
          end
        end
      end
    end

    context "for a successful Casper runner" do
      before do
        File.stub(:foreach).and_yield 'describe("SuccessTest", function() {'
        IO.stub(:popen).and_return StringIO.new(casperjs_success_response)
      end

      it 'requests the casper scenarios from the server' do
        File.should_receive(:foreach).with('scenario/javascripts/t.js').and_yield 'describe("SuccessTest", function() {'
        IO.should_receive(:popen).with("#{ casperjs_command } \"http://localhost:8888/casper?scenario=SuccessTest\" 10000 failure true failure failure")

        runner.run(['scenario/javascripts/t.js'], defaults)
      end

      it 'returns the success' do
        response = runner.run(['scenario/javascripts/x/b.js.coffee'], defaults)
        response.first.should be_true
        response.last.should =~ []
      end

      context 'with the scenariodoc set to :always' do
        it 'shows the scenariodoc in the console' do
          formatter.should_receive(:info).with(
              'Run Casper suite scenario/javascripts/x/t.js', { :reset => true }
          )
          formatter.should_receive(:info).with(
              'Run Casper suite at http://localhost:8888/casper?scenario=SuccessTest'
          )
          formatter.should_receive(:suite_name).with(
              'Success suite'
          )
          formatter.should_receive(:success).with(
              '  ✔ Success test tests something'
          )
          formatter.should_receive(:success).with(
              '  ✔ Another success test tests something'
          )
          formatter.should_receive(:suite_name).with(
               '  Nested success suite'
           )
          formatter.should_receive(:success).with(
              '    ✔ Success nested test tests something'
          )
          formatter.should_receive(:success).with(
              "3 scenarios, 0 failures"
          )
          runner.run(['scenario/javascripts/x/t.js'], defaults.merge({ :scenariodoc => :always }))
        end

        context 'with console logs set to :always' do
          it 'shows the console logs' do
            formatter.should_receive(:info).with(
                'Run Casper suite scenario/javascripts/x/b.js.coffee', { :reset => true }
            )
            formatter.should_receive(:info).with(
                'Run Casper suite at http://localhost:8888/casper?scenario=SuccessTest'
            )
            formatter.should_receive(:info).with(
                "    • I can haz console.logs"
            )
            runner.run(['scenario/javascripts/x/b.js.coffee'], defaults.merge({ :scenariodoc => :always, :console => :always }))
          end
        end

        context 'with console logs set to :never' do
          it 'does not shows the console logs' do
            formatter.should_not_receive(:info).with(
                "    • I can haz console.logs"
            )
            runner.run(['scenario/javascripts/x/b.js.coffee'], defaults.merge({ :scenariodoc => :always, :console => :never }))
          end
        end
      end

      context 'with the scenariodoc set to :never or :failure' do
        it 'shows the summary in the console' do
          formatter.should_receive(:info).with(
              'Run Casper suite scenario/javascripts/x/t.js', { :reset => true }
          )
          formatter.should_receive(:info).with(
              'Run Casper suite at http://localhost:8888/casper?scenario=SuccessTest'
          )
          formatter.should_not_receive(:suite_name)
          formatter.should_receive(:success).with(
              "3 scenarios, 0 failures"
          )
          runner.run(['scenario/javascripts/x/t.js'], defaults.merge({ :scenariodoc => :never }))
        end
      end

      context 'with notifications' do
        it 'shows a success notification' do
          formatter.should_receive(:notify).with(
              "3 scenarios, 0 failures\nin 0.009 seconds",
              :title => 'Casper suite passed'
          )
          runner.run(['scenario/javascripts/t.js'], defaults)
        end

        context 'with hide success notifications' do
          it 'does not shows a success notification' do
            formatter.should_not_receive(:notify)
            runner.run(['scenario/javascripts/t.js'], defaults.merge({ :notification => true, :hide_success => true }))
          end
        end
      end

      context 'without notifications' do
        it 'does not shows a success notification' do
          formatter.should_not_receive(:notify)
          runner.run(['scenario/javascripts/t.js'], defaults.merge({ :notification => false }))
        end
      end
    end

  end

end
