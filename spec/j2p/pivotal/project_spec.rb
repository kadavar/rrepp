require 'rails_helper'

describe JiraToPivotal::Pivotal::Project do
  before do
    allow(client).to receive(:project).and_return(inner_project)
    allow(TrackerApi::Client).to receive(:new).and_return(client)
  end

  let(:inner_project) { double 'inner project' }
  let(:logger)        { double 'logger' }
  let(:client)        { double 'client' }
  let(:error)         { double 'error' }

  let(:config) { { 'retry_count' => '1', 'tracker_token' => 'token' } }
  let(:project) { JiraToPivotal::Pivotal::Project.new(config) }

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

        is_expected.to eq({ })
      end
    end
  end

  describe '#map_users_by_email' do
    context 'on TrackerApi error' do
      before do
        allow(inner_project).to receive(:memberships) do
          fail TrackerApi::Error.new(error), 'error'
        end
      end
      before { config['retry_count'] = '2' }

      specify 'retries two times and didnt raises error' do
        expect(project).to receive(:airbrake_report_and_log).exactly(2).times

        expect{ project.map_users_by_email }.not_to raise_exception TrackerApi::Error
      end
    end

    context 'on general exception' do
      before { allow(inner_project).to receive(:memberships) { fail 'error' } }
      before { config['retry_count'] = '2' }

      specify 'retries two times and raises error' do
        expect(project).to receive(:airbrake_report_and_log).exactly(2).times

        expect{ project.map_users_by_email }.to raise_exception
      end
    end
  end

  describe '#build_project' do
    before do
      allow(project).to receive(:build_project).and_call_original
      allow(project).to receive(:pivotal_log) { }
    end
    context 'on TrackerApi error' do
      before do
        allow(TrackerApi::Client).to receive(:new) do
          fail TrackerApi::Error.new(error), 'error'
        end
      end
      before { config['retry_count'] = '2' }

      specify 'retries 2 times, didnt send airbrake notification, no error' do
        expect(Airbrake).to receive(:notify_or_ignore).exactly(0).times
        expect(logger).to receive(:error_log).exactly(2).times

        expect{ project.build_project }.not_to raise_exception TrackerApi::Error
      end
    end

    context 'on general exception' do
      before { allow(TrackerApi::Client).to receive(:new) { fail 'error' } }
      before { config['retry_count'] = '2' }

      specify 'retries 2 times, didnt send airbrake notification' do
        expect(Airbrake).to receive(:notify_or_ignore).exactly(0).times
        expect(logger).to receive(:error_log).exactly(2).times

        expect{ project.build_project }.to raise_exception
      end
    end
  end
  describe '#update config' do
    subject { project.update_config(opt) }

    context 'when options is empty' do
     let(:opt) { {} }
      it { is_expected.to eq config }
    end

    context 'when options is merged' do
      let(:result) { { 'retry_count'=>'1', 'new'=>'option' } }
      let(:opt) { { 'new' => 'option' } }

      it { is_expected.to eq result }
    end

  end
  describe '#unsynchronized_stories' do
    before do
      allow(inner_project).to receive(:stories).and_return(story)
    end

    subject { project.unsynchronized_stories }

    let(:story) { double 'stories' }
    let(:to_create) { double 'stories' }

    context 'when return hash' do
      before do
        allow(to_create).to receive(:map).and_return('to_create')
        allow(story).to receive(:select).and_return(to_create)
      end

      let(:result) { { to_create: 'to_create', to_update: 'to_create' } }

      it { is_expected.to eq result }
    end

    context 'when result empty ' do
      before do
        allow(to_create).to receive(:map).and_return({ })
        allow(story).to receive(:select).and_return(to_create)
      end

      let(:result) { { to_create: { } , to_update: { } } }

      it { is_expected.to eq result }
    end
  end

  describe '#story_ends_with_nil?' do
    let(:story) { double 'story' }
    subject { project.send(:story_ends_with_nil?,story) }

    context 'when external_id is not present ' do
      before { allow(story).to receive(:external_id).and_return(nil) }
      it { is_expected.to be true }
    end

    context 'when last digit !=0 ' do
      before { allow(story).to receive(:external_id).and_return('23-24-5') }
      it { is_expected.to be false }
    end

    context 'when last digit == 0 ' do
      before { allow(story).to receive(:external_id).and_return('23-24-0') }
      it { is_expected.to be  true }
    end
  end

  describe '#select_tasks' do
    let(:stories) { double 'story' }
    let(:issue)   { double 'issue' }

    before { allow(stories).to receive(:external_id) { 1 } }
    before { allow(issue).to receive(:key) { 1 } }

    subject { project.select_task(stories,issue) }

    context 'when external_id==issue.key' do
      before do
        allow(stories).to receive(:find) { 'true' if stories.external_id == issue.key  }
      end

      it { is_expected.to eq 'true' }
    end
  end

  describe '#find_stories_by' do
    let(:story_1) { double 'stories' }

    before { allow(inner_project).to receive(:stories).and_return(story_1) }

    subject { project.send(:find_stories_by) }

    context 'd' do
      it { is_expected.to eq story_1 }
    end
  end
end
