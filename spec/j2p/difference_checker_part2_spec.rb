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

  describe '#reporter?' do
    subject { difference_checker.send(:reporter?, params) }

    let(:user_permissions) { double 'user permissions' }

    before { allow(difference_checker).to receive(:user_permissions) { user_permissions } }

    describe 'without ability to modify reporter' do
      before { allow(user_permissions).to receive(:modify_reporter?) { false } }

      it { is_expected.to be false }
    end

    describe 'with ability to modify reporter' do
      before { allow(user_permissions).to receive(:modify_reporter?) { true } }

      describe 'with jira and pivotal reporter exists' do
        before do
          allow(difference_checker).to receive(:story_reporter) { { 'name' => 'John' } }
          allow(difference_checker).to receive(:jira_reporter) { { 'name' => 'John' } }
        end

        context 'names similar' do
          it { is_expected.to be false }
        end

        context 'different names' do
          before { allow(difference_checker).to receive(:jira_reporter) { { 'name' => 'Mike' } } }

          it { is_expected.to be true }
        end
      end

      describe 'without reporters' do
        before do
          allow(difference_checker).to receive(:story_reporter) { nil }
          allow(difference_checker).to receive(:jira_reporter) { nil }
        end

        context 'without any reporters' do
          it { is_expected.to be nil }
        end

        context 'without jira reporter' do
          before { allow(difference_checker).to receive(:story_reporter) { { 'name' => 'John' } } }

          it { is_expected.to be true }
        end

        context 'without pivotal' do
          before { allow(difference_checker).to receive(:jira_reporter) { { 'name' => 'John' } } }

          it { is_expected.to be nil }
        end
      end
    end
  end

  describe '#assignee?' do
    subject { difference_checker.send(:asignee?, params) }

    let(:user_permissions) { double 'user permissions' }

    before { allow(difference_checker).to receive(:user_permissions) { user_permissions } }

    describe 'without ability to assign issue' do
      before { allow(user_permissions).to receive(:assign_issue?) { false } }

      it { is_expected.to be false }
    end

    describe 'with ability to assign issue' do
      before { allow(user_permissions).to receive(:assign_issue?) { true } }

      describe 'with story and jira assignees' do
        before do
          allow(difference_checker).to receive(:story_assignee) { { 'name' => 'John' } }
          allow(difference_checker).to receive(:jira_assignee) { { 'name' => 'John' } }
        end

        context 'names are similar' do
          it { is_expected.to be false }
        end

        context 'names are different' do
          before { allow(difference_checker).to receive(:jira_assignee) { { 'name' => 'Mike' } } }

          it { is_expected.to be true }
        end
      end

      describe 'without assignees' do
        before do
          allow(difference_checker).to receive(:story_assignee) { nil }
          allow(difference_checker).to receive(:jira_assignee) { nil }
        end

        context 'without any reporters' do
          it { is_expected.to be nil }
        end

        context 'with pivotal reporter' do
          before { allow(difference_checker).to receive(:story_assignee) { { 'name' => 'John' } } }

          it { is_expected.to be true }
        end

        context 'with jira reporter' do
          before { allow(difference_checker).to receive(:jira_assignee) { { 'name' => 'John' } } }

          it { is_expected.to be nil }
        end
      end
    end
  end

  describe '#difference_between_pivotal_jira?' do
    subject { difference_checker.send(:difference_between_pivotal_jira?, params) }

    before do
      allow(difference_checker).to receive(:summary?) { false }
      allow(difference_checker).to receive(:description?) { false }
      allow(difference_checker).to receive(:task_type?) { false }
      allow(difference_checker).to receive(:reporter?) { false }
      allow(difference_checker).to receive(:asignee?) { false }
      allow(difference_checker).to receive(:estimates?) { false }
    end

    context 'all checks false' do
      it { is_expected.to be false }
    end

    context 'summary true' do
      before { allow(difference_checker).to receive(:summary?) { true } }

      it { is_expected.to be true }
    end

    context 'description true' do
      before { allow(difference_checker).to receive(:description?) { true } }

      it { is_expected.to be true }
    end

    context 'task_type true' do
      before { allow(difference_checker).to receive(:task_type?) { true } }

      it { is_expected.to be true }
    end

    context 'reporter true' do
      before { allow(difference_checker).to receive(:reporter?) { true } }

      it { is_expected.to be true }
    end

    context 'asignee true' do
      before { allow(difference_checker).to receive(:asignee?) { true } }

      it { is_expected.to be true }
    end

    context 'estimates true' do
      before { allow(difference_checker).to receive(:estimates?) { true } }

      it { is_expected.to be true }
    end
  end
end
