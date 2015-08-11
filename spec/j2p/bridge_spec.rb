require 'rails_helper'

describe JiraToPivotal::Bridge do
  let(:pivotal) { double 'pivotal' }
  let(:logger) { double 'logger' }
  let(:jira) { double 'jira' }
  let(:jira_logger) { double 'jira logger' }

  before do
    allow_any_instance_of(JiraToPivotal::Bridge).to receive(:decrypt_config) { {} }
  end

  let(:bridge) { JiraToPivotal::Bridge.new({}) }

  before do
    allow(bridge).to receive(:pivotal) { pivotal }
    allow(bridge).to receive(:jira) { jira }
    allow(bridge).to receive(:connect_jira_to_pivotal!) { {} }
    allow(bridge).to receive(:from_pivotal_to_jira!) { {} }
  end

  before { allow(jira).to receive(:logger) { jira_logger } }
  before { allow(jira_logger).to receive(:error_log) {} }
  before { allow(pivotal).to receive(:update_config) { {} } }

  describe '#sync!' do
    subject(:sync) { bridge.sync! }

    context 'raise error' do
      before { allow(bridge).to receive(:connect_jira_to_pivotal!) { fail } }

      specify 'raises error' do
        expect { sync }.to raise_exception
      end
    end
  end
end
