require 'rails_helper'
include PivotalStoryHelpers

describe JiraToPivotal::Pivotal::Story do
  let(:project) { create :project }
  let(:conf) { create :config }
  let(:inner_story) { double 'inner story' }
  let!(:pivotal_story) { JiraToPivotal::Pivotal::Story.new(project, inner_story, conf) }
  let(:custom_fields) { { 'points' => 'Story Points', 'url' => 'Pivotal Tracker URL' } }
  let(:logger) { double 'logger' }

  before { allow(pivotal_story).to receive(:story) { inner_story } }
  before { allow(Airbrake).to receive(:notify_or_ignore) {} }

  before do
    allow(conf).to receive(:airbrake_message_parameters) {}
    allow(conf).to receive(:[]).with('retry_count') { 2 }
    allow(conf).to receive(:[]).with('repeat_delay') { 2 }
    allow(conf).to receive(:[]).with('tracker_project_id') { 2 }
  end

  before { allow(logger).to receive(:error_log) {} }
  before { allow(pivotal_story).to receive(:logger) { logger } }

  describe '#to_jira' do
    subject { pivotal_story.to_jira(custom_fields) }
    let(:ownership_handler) { double 'ownership handler' }
    before { allow(conf).to receive(:[]).with(:ownership_handler) { ownership_handler } }
    before do
      allow(pivotal_story).to receive(:main_attrs) do
        {
            'summary' => 'summary',
            'description' => 'description',
            'issuetype' => { 'id' => '1' }
        }
      end
      allow(pivotal_story).to receive(:original_estimate_attrs) { { 'estimate' => 'estimate' } }
      allow(pivotal_story).to receive(:custom_fields_attrs) { { 'pivotal' => 'pivotal' } }
    end
    before do
      allow(ownership_handler).to receive(:reporter_and_asignee_attrs) { { 'reporter' => 'reporter' } }
    end

    context 'without error' do
      it 'returns valid jira issue' do
        is_expected.to eq(
                           'summary' => 'summary',
                           'description' => 'description',
                           'issuetype' => { 'id' => '1' },
                           'estimate' => 'estimate',
                           'pivotal' => 'pivotal',
                           'reporter' => 'reporter'
                        )
      end
    end

    context 'with error' do
      before { allow(pivotal_story).to receive(:ownership_handler) { fail } }

      specify 'retryes 2 times and false' do
        expect(pivotal_story).to receive(:main_attrs).exactly(2).times

        is_expected.to be false
      end
    end
  end

  describe '#main_attrs' do
    subject(:attrs) { pivotal_story.main_attrs }
    let(:issue_types) { { 'bug' => '3', 'feature' => '4', 'chore' => '5' } }
    before do
      allow(inner_story).to receive(:description) { 'description' }
      allow(inner_story).to receive(:story_type) { 'bug' }
    end
    before { allow(conf).to receive(:[]).with('jira_issue_types') { issue_types } }

    context 'with clear summary' do
      before { allow(inner_story).to receive(:name) { 'clear name' } }

      it 'returns correct story' do
        expect(attrs['summary']).to eq 'clear name'
        expect(attrs['description']).to eq 'description'
        expect(attrs['issuetype']['id']).to eq '3'
      end
    end

    context 'with special chars in summary' do
      let(:chars) { ["\t", "\n"] }
      before { allow(inner_story).to receive(:name) { generate_summary(255, true) } }

      it 'returns correct story' do
        expect(chars.any? { |char| attrs['summary'].include?(char) }).to be false
        expect(attrs['description']).to eq 'description'
        expect(attrs['issuetype']['id']).to eq '3'
      end
    end

    context 'with summary more then 255 chars' do
      before { allow(inner_story).to receive(:name) { generate_summary(256, false) } }

      it 'returns correct story' do
        expect(attrs['summary'].length).to be 255
        expect(attrs['description']).to eq 'description'
        expect(attrs['issuetype']['id']).to eq '3'
      end
    end
  end

  describe '#description_with_replaced_image_tag' do
    subject { pivotal_story.description_with_replaced_image_tag }

    let(:description) { double 'description' }

    before do
      allow(inner_story).to receive(:description) { description }

      allow(pivotal_story).to receive (:regexp_for_image_tag_replace) { /\!\[\w+ *\w+\]\(([\w\p{P}\p{S}]+) *\"*\w* *\w*\"*\)/u }
    end

    context 'without title' do
      before { allow(description).to receive(:to_s) { '![tinyarrow](https://examp.net/icon_linux.gif)' } }

      it { is_expected.to eq '!https://examp.net/icon_linux.gif!' }
    end

    context 'with title' do
      before { allow(description).to receive(:to_s) { '![tinyarrow](https://examp.net/icon_linux.gif "tiny arrow")' } }

      it { is_expected.to eq '!https://examp.net/icon_linux.gif!' }
    end

    context 'with whitespace in alt' do
      before { allow(description).to receive(:to_s) { '![tiny arrow](https://examp.net/icon_linux.gif)' } }

      it { is_expected.to eq '!https://examp.net/icon_linux.gif!' }
    end
  end

  describe '#set_original_estimate?' do
    subject { pivotal_story.set_original_estimate? }

    before do
      allow(inner_story).to receive(:current_state) { 'nonstarted' }
      allow(inner_story).to receive(:story_type) { 'type' }
      allow(inner_story).to receive(:estimate) { '-1' }
    end

    context 'unstarted and started false' do
      it { is_expected.to be false }
    end

    describe 'unstarted or started' do
      before { allow(inner_story).to receive(:current_state) { 'started' } }

      context 'bug or chore' do
        before { allow(inner_story).to receive(:story_type) { 'chore' } }
        it { is_expected.to be false }
      end

      describe 'not bug or chore' do
        before do
          allow(pivotal_story).to receive(:bug?) { false }
          allow(pivotal_story).to receive(:chore?) { false }
        end

        context 'with empty estimate' do
          it { is_expected.to be false }
        end

        context 'with estimate' do
          before { allow(inner_story).to receive(:current_state) { 'started' } }
          before { allow(inner_story).to receive(:story_type) { 'type' } }
          before { allow(inner_story).to receive(:estimate) { '1' } }

          it { is_expected.to be true }
        end
      end
    end
  end

  describe '#original_estimate_attrs' do
    subject { pivotal_story.original_estimate_attrs }

    before { allow(inner_story).to receive(:estimate) { '2' } }

    context 'with set_original_estimate?' do
      before { allow(pivotal_story).to receive(:set_original_estimate?) { true } }

      it { is_expected.to eq('timetracking' => { 'originalEstimate' => '2h' }) }
    end

    context 'without set_original_estimate?' do
      before { allow(pivotal_story).to receive(:set_original_estimate?) { false } }

      it { is_expected.to eq({}) }
    end
  end

  describe '#custom_fields_attrs' do
    subject(:fields_attrs) { pivotal_story.custom_fields_attrs(custom_fields) }

    before do
      allow(pivotal_story).to receive(:bug?) { true }
      allow(pivotal_story).to receive(:chore?) { true }
      allow(pivotal_story).to receive(:empty_estimate?) { true }

      allow(inner_story).to receive(:url) { 'url' }
      allow(inner_story).to receive(:estimate) { '4' }
    end

    describe 'without pivotal url' do
      before do
        allow(pivotal_story).to receive(:config) do
          {
              'jira_custom_fields' => { 'pivotal_url' => '',
                                        'pivotal_points' => 'Story Points' }
          }
        end
      end

      context 'bug, chore or empty estimate' do
        it { expect(fields_attrs.empty?).to be true }
      end

      context 'not bug, chore or empty estimate' do
        before do
          allow(pivotal_story).to receive(:bug?) { false }
          allow(pivotal_story).to receive(:chore?) { false }
          allow(pivotal_story).to receive(:empty_estimate?) { false }
        end

        it 'returns points and nil url' do
          expect(fields_attrs['points']).to be 4
          expect(fields_attrs['url']).to be nil
        end
      end
    end

    describe 'with pivotal url' do
      before do
        allow(pivotal_story).to receive(:config) do
          {
              'jira_custom_fields' => { 'pivotal_url' => 'Pivotal Tracker URL',
                                        'pivotal_points' => 'Story Points' }
          }
        end
      end

      context 'bug, chore or empty estimate' do
        it 'returns url and nil points' do
          expect(fields_attrs['points']).to be nil
          expect(fields_attrs['url']).to eq 'url'
        end
      end

      context 'not bug, chore or empty estimate' do
        before do
          allow(pivotal_story).to receive(:bug?) { false }
          allow(pivotal_story).to receive(:chore?) { false }
          allow(pivotal_story).to receive(:empty_estimate?) { false }
        end

        it 'returns url and points' do
          expect(fields_attrs['points']).to be 4
          expect(fields_attrs['url']).to eq 'url'
        end
      end
    end
  end

  describe '#notes' do
    context 'error rises' do
      before { allow(inner_story).to receive(:comments) { fail } }

      specify 'retryes 2 times and returns false' do
        expect(inner_story).to receive(:comments).exactly(2).times

        expect(pivotal_story.notes).to be false
      end
    end
  end

  describe '#assign_to_jira_issue' do
    let(:key) { double 'key' }
    let(:story) { double 'story' }
    let(:jira_url) { double 'jira_url' }
    let(:integration) { { 'id' => 3 } }
    let(:integrations) { double 'integrations' }
    before do
      allow(integrations).to receive(:select) { [integration] }
      allow(integrations).to receive(:body) { integrations }
    end

    let(:client) { double 'client' }
    before { allow(client).to receive(:get) { integrations } }

    before { allow(inner_story).to receive(:id) { 3 } }
    before do
      allow(story).to receive(:external_id=) { key }
      allow(story).to receive(:integration_id=).and_return(integration['id'])
      allow(story).to receive(:save) { 'save' }
    end
    before do
      allow(project).to receive(:story) { story }
      allow(project).to receive(:client) { client }
    end
    subject { pivotal_story.assign_to_jira_issue(key, jira_url) }

    context 'when integration present' do
      it { is_expected.to eq 'save' }
      context 'option key is nil' do
        let(:key) { nil }
        it { is_expected.to eq 'save' }
      end
    end

    context 'when integration is not present' do
      let(:integration) { {} }
      before { allow(logger).to receive(:attrs_log) { 'attrs_log' } }
      it { is_expected.to eq false }
    end
  end

  describe '#jira_issue_id' do
    before { allow(inner_story).to receive(:external_id) { 'external_id' } }
    subject { pivotal_story.jira_issue_id }
    it { is_expected.to eq 'external_id' }
  end

  describe '#current_story_status_to_issue_status' do
    before { allow(inner_story).to receive(:current_state) { 'rejected' } }
    subject { pivotal_story.current_story_status_to_issue_status }
    it { is_expected.to eq 'Reopened' }
  end

  describe '#story_status_to_issue_status' do
    before { allow(inner_story).to receive(:current_state) { 'rejected' } }
    subject { pivotal_story.story_status_to_issue_status }
    it { is_expected.to eq 'Reopen Issue' }
  end
end
