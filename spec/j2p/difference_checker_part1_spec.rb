require 'rails_helper'

describe JiraToPivotal::DifferenceChecker do
  let(:client) { double 'client' }

  before { allow(client).to receive(:user_permissions) { { 'permissions' => {} } } }

  let(:config) do
    { custom_fields: { 'field_id' => 'Story Points' },
      'jira_custom_fields' => { 'pivotal_points' => 'Story Points' } }
  end

  let(:difference_checker) { JiraToPivotal::DifferenceChecker.new(client, config) }
  let(:params) { {} }

  describe '#task_type?' do
    subject { difference_checker.send(:task_type?, params) }

    let(:j2p_issue) { double 'j2p issue' }
    let(:jira_issue) { double 'jira issue' }
    let(:story_attrs) { { 'fields' => { 'issuetype' => { 'id' => 2 } } } }
    let(:params) { { j2p_issue: j2p_issue, jira_issue: jira_issue, story_attrs: story_attrs } }

    context 'subtask true' do
      before { allow(j2p_issue).to receive(:subtask?) { true } }

      it { is_expected.to be false }
    end

    describe 'subtask false' do
      before { allow(j2p_issue).to receive(:subtask?) { false } }

      context 'with similar ids' do
        before { allow(jira_issue).to receive(:fields) { { 'issuetype' => { 'id' => 2 } } } }

        it { is_expected.to be false }
      end

      context 'with different ids' do
        before { allow(jira_issue).to receive(:fields) { { 'issuetype' => { 'id' => 3 } } } }

        it { is_expected.to be true }
      end
    end
  end

  describe '#estimates?' do
    subject { difference_checker.send(:estimates?, params) }

    context 'with incorrect issue type' do
      before { allow(difference_checker).to receive(:incorrect_issue_type?) { true } }

      it { is_expected.to be false }
    end

    describe 'with correct issue type' do
      let(:jira_issue) { double 'jira issue' }

      before do
        allow(difference_checker).to receive(:incorrect_issue_type?) { false }

        params[:jira_issue] = jira_issue
        params[:story_attrs] = { 'fields' => { 'field_id' => 4 } }
      end

      describe 'with similar estimates' do
        before { allow(jira_issue). to receive(:fields) { { 'field_id' => 4 } } }

        context 'with non empty estimate' do
          before { allow(difference_checker).to receive(:empty_estimate?) { false } }

          it { is_expected.to be false }
        end

        context 'with empty estimates' do
          before { allow(difference_checker).to receive(:empty_estimate?) { true } }

          it { is_expected.to be true }
        end
      end

      describe 'with different estimates' do
        before { allow(jira_issue). to receive(:fields) { { 'field_id' => 4 } } }

        context 'with non empty estimate' do
          before { allow(difference_checker).to receive(:empty_estimate?) { false } }

          it { is_expected.to be false }
        end

        context 'with empty estimates' do
          before { allow(difference_checker).to receive(:empty_estimate?) { true } }

          it { is_expected.to be true }
        end
      end
    end
  end

  describe '#incorrect_issue_type?' do
    let(:j2p_issue) { double 'j2p_issue' }

    subject { difference_checker.send(:incorrect_issue_type?, params) }
    before do
      allow(j2p_issue).to receive(:bug?) { false }
      allow(j2p_issue).to receive(:chore?) { false }
      allow(j2p_issue).to receive(:subtask?) { false }
      params[:j2p_issue] = j2p_issue
    end

    context 'all issues false' do
      it { is_expected.to be false }
    end

    context 'bug incorrect' do
      before { allow(j2p_issue).to receive(:bug?) { true } }

      it { is_expected.to be true }
    end

    context 'chore incorrect' do
      before { allow(j2p_issue).to receive(:chore?) { true } }

      it { is_expected.to be true }
    end

    context 'subtask incorrect' do
      before { allow(j2p_issue).to receive(:subtask?) { true } }

      it { is_expected.to be true }
    end
  end

  describe '#status?' do
    subject { difference_checker.send(:status?, jira_issue, story) }

    let(:story) { double 'story' }
    let(:jira_issue) { double 'jira_issue' }

    describe 'with similar statuses' do
      before do
        allow(story).to receive(:current_story_status_to_issue_status) { 'open' }
        allow(jira_issue).to receive(:fields) { { 'status' => { 'name' => 'open' } } }
      end

      it { is_expected.to be false }
    end

    describe 'with different statuses' do
      before do
        allow(story).to receive(:current_story_status_to_issue_status) { 'open' }
        allow(jira_issue).to receive(:fields) { { 'status' => { 'name' => 'closed' } } }
      end

      it { is_expected.to be true }
    end
  end
end
