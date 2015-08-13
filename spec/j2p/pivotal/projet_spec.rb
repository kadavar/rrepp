require 'rails_helper'

describe JiraToPivotal::Pivotal::Project do
  before { allow_any_instance_of(JiraToPivotal::Pivotal::Project).to receive(:build_project) {} }

  let(:config) { { 'script_repeat_time' => '1' } }
  let(:project) { JiraToPivotal::Pivotal::Project.new(config) }
  let(:inner_project) { double 'inner project' }
  let(:logger) { double 'logger' }
  let(:client) { double 'client' }
  let(:error) { double 'error' }

  before do
    allow(error).to receive(:message) { 'message' }
    allow(error).to receive(:code) { 'code' }
    allow(error).to receive(:response) { 'responcse' }
  end

  before { allow(config).to receive(:airbrake_message_parameters) {} }
  before { allow(logger).to receive(:error_log) {} }

  before do
    allow(project).to receive(:project) { inner_project }
    allow(project).to receive(:logger) { logger }
    allow(project).to receive(:client) { client }
  end

  describe '#usefull_stories' do
    subject { project.send :usefull_stories }

    describe 'skip airbrake notification on TrackerApi::Error' do
      before { allow(inner_project).to receive(:stories) { fail TrackerApi::Error.new(error), 'error' } }

      specify 'logs and skips airbrake' do
        expect(Airbrake).to receive(:notify_or_ignore).exactly(0).times
        expect(logger).to receive(:error_log).exactly(1).times

        is_expected.to be nil
      end
    end
  end

  describe '#map_users_by_email' do
    describe 'on error' do
      before { allow(inner_project).to receive(:memberships) { fail TrackerApi::Error.new(error), 'error' } }
      before { config['script_repeat_time'] = '2' }

      specify 'retries two times and raises error' do
        expect(project).to receive(:airbrake_report_and_log).exactly(2).times

        expect{ project.map_users_by_email }.to raise_exception TrackerApi::Error
      end
    end
  end

  describe '#build_project' do
    before do
      allow(project).to receive(:build_project).and_call_original
      allow(project).to receive(:pivotal_log) { }
    end

    describe 'on error' do
      before { allow(TrackerApi::Client).to receive(:new) { fail fail TrackerApi::Error.new(error), 'error' } }
      before { config['script_repeat_time'] = '2' }

      specify 'retries 2 times, didnt send airbrake notification' do
        expect(Airbrake).to receive(:notify_or_ignore).exactly(0).times
        expect(logger).to receive(:error_log).exactly(2).times

        expect{ project.build_project }.to raise_exception TrackerApi::Error
      end
    end
  end
end
