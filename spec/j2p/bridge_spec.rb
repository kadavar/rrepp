require 'rails_helper'

describe JiraToPivotal::Bridge do
  let(:pivotal) { double 'pivotal' }
  let(:logger) { double 'logger' }
  let(:jira) { double 'jira' }
  let(:jira_logger) { double 'jira logger' }
  let(:config) { { 'script_repeat_time' => '1', 'retry_count' => '1', 'log_file_name' => 'log' } }

  before { allow_any_instance_of(JiraToPivotal::Bridge).to receive(:decrypt_config) { {} } }

  let(:bridge) { JiraToPivotal::Bridge.new({}) }

  before do
    allow(bridge).to receive(:pivotal) { pivotal }
    allow(bridge).to receive(:jira) { jira }
    allow(bridge).to receive(:init_logger) { {} }
    allow(bridge).to receive(:from_pivotal_to_jira!) { {} }
    allow(bridge).to receive(:config) { config }
    allow(bridge).to receive(:airbrake_report_and_log) {}
    allow(bridge).to receive(:loger) { logger }
  end

  before do
    allow(jira).to receive(:logger) { jira_logger }
    allow(jira).to receive(:project) { {} }
  end

  before { allow(config).to receive(:airbrake_message_parameters) {} }
  before { allow(jira_logger).to receive(:error_log) {} }
  before { allow(pivotal).to receive(:update_config) { {} } }

  describe '#sync!' do
    subject(:sync) { bridge.sync! }

    context 'no pivotal' do
      before { allow(pivotal).to receive(:project) { fail(RuntimeError, 'Bad case') } }
      before { allow(jira).to receive(:project) { {} } }

      specify 'raises error' do
        expect { sync }.to raise_exception(RuntimeError, 'Bad case')
      end
    end

    context 'no jira' do
      before { allow(jira).to receive(:project) { fail(RuntimeError, 'Bad case') } }

      specify 'raises error' do
        expect { sync }.to raise_exception(RuntimeError, 'Bad case')
      end
    end

    context 'raise SocketError' do
      before { allow(pivotal).to receive(:update_config) { fail(SocketError, 'Bad case') } }

      specify 'without error' do
        expect { sync }.not_to raise_error(SocketError, 'Bad case')
      end
    end
  end
end
