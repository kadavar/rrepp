require 'rails_helper'
include JiraProjectsHelper
describe JiraToPivotal::Jira::OwnershipHandler do
  let(:pivotal) { double 'pivotal' }
  let(:jira) { double 'jira' }
  let(:story) { double 'story' }
  let(:config) { { 'script_repeat_time' => '5m', 'repeat_delay' => 0 } }
  let!(:handler) { JiraToPivotal::Jira::OwnershipHandler.new(jira, pivotal, config) }

  describe 'reporter_and_asignee_attrs' do
    subject(:attrs) { handler.reporter_and_asignee_attrs(story) }

    context 'raise an TrackerApi::Error' do
      before { allow(story).to receive(:owners) { fail(TrackerApi::Error, instance_double('error', response: 'message')) } }
      before { allow(config).to receive(:airbrake_message_parameters) { 'params' } }
      before { allow(handler).to receive(:airbrake_report_and_log) { true } }
      it 'should return empty hash ' do
        expect(attrs).to eq Hash.new
      end
    end

    context 'raise an JIRA::HTTPError' do
      before { allow(story).to receive(:owners) { fail(JIRA::HTTPError, instance_double('error', message: 'message')) } }
      it 'should fail' do
        expect { attrs }.to raise_exception(JIRA::HTTPError)
      end
    end
  end
end
