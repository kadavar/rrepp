require 'rails_helper'

describe JiraToPivotal::DifferenceChecker do
  let(:client) { double 'client' }

  before { allow(client).to receive(:user_permissions) { { 'permissions' => {} } } }

  let(:config) do
    { custom_fields: { 'points_field' => 'Story Points' },
      'jira_custom_fields' => { 'pivotal_points' => 'Story Points' } }
  end

  let(:difference_checker) { JiraToPivotal::DifferenceChecker.new(client, config) }
  let(:params) { {} }
  let(:user_permissions) { double 'user permissions' }

  before { allow(difference_checker).to receive(:user_permissions) { user_permissions } }

  describe '#main_attrs_difference?' do
    subject { difference_checker.main_attrs_difference?(story_attrs, j2p_issue) }

    let(:story_attrs) do
      {
        'fields' => {
          'summary' => 'summary',
          'description' => 'description',
          'issuetype' => { 'id' => 2 },
          'reporter' => { 'name' => 'name' },
          'assignee' => { 'name' => 'name' },
          'points_field' => 4
        }
      }
    end
    let(:j2p_issue) { double 'j2p issue' }
    let(:jira_issue) { double 'jira issue' }

    before do
      allow(j2p_issue).to receive(:issue) { jira_issue }
      allow(j2p_issue).to receive(:bug?) { false }
      allow(j2p_issue).to receive(:chore?) { false }
      allow(j2p_issue).to receive(:subtask?) { false }
    end

    before do
      allow(user_permissions).to receive(:modify_reporter?) { false }
      allow(user_permissions).to receive(:assign_issue?) { false }
    end

    context 'with similar attrs' do
      before do
        allow(jira_issue).to receive(:fields) do
          {
            'summary' => 'summary',
            'description' => 'description',
            'issuetype' => { 'id' => 2 },
            'reporter' => { 'name' => 'name' },
            'assignee' => { 'name' => 'name' },
            'points_field' => 4,
            'timeoriginalestimate' => 4
          }
        end
      end

      it { is_expected.to be false }
    end

    context 'different summary' do
      before do
        allow(jira_issue).to receive(:fields) do
          {
            'summary' => 'different summary',
            'description' => 'description',
            'issuetype' => { 'id' => 2 },
            'reporter' => { 'name' => 'name' },
            'assignee' => { 'name' => 'name' },
            'points_field' => 4,
            'timeoriginalestimate' => 4
          }
        end
      end

      it { is_expected.to be true }
    end

    context 'different description' do
      before do
        allow(jira_issue).to receive(:fields) do
          {
            'summary' => 'summary',
            'description' => 'different description',
            'issuetype' => { 'id' => 2 },
            'reporter' => { 'name' => 'name' },
            'assignee' => { 'name' => 'name' },
            'points_field' => 4,
            'timeoriginalestimate' => 4
          }
        end
      end

      it { is_expected.to be true }
    end

    context 'different task types' do
      before do
        allow(jira_issue).to receive(:fields) do
          {
            'summary' => 'summary',
            'description' => 'description',
            'issuetype' => { 'id' => 3 },
            'reporter' => { 'name' => 'name' },
            'assignee' => { 'name' => 'name' },
            'points_field' => 4,
            'timeoriginalestimate' => 4
          }
        end
      end

      it { is_expected.to be true }
    end

    context 'different reporter names' do
      before { allow(user_permissions).to receive(:modify_reporter?) { true } }

      before do
        allow(jira_issue).to receive(:fields) do
          {
            'summary' => 'summary',
            'description' => 'description',
            'issuetype' => { 'id' => 2 },
            'reporter' => { 'name' => 'different name' },
            'assignee' => { 'name' => 'name' },
            'points_field' => 4,
            'timeoriginalestimate' => 4
          }
        end
      end

      it { is_expected.to be true }
    end

    context 'different assignee names' do
      before { allow(user_permissions).to receive(:assign_issue?) { true } }
      before do
        allow(jira_issue).to receive(:fields) do
          {
            'summary' => 'summary',
            'description' => 'description',
            'issuetype' => { 'id' => 2 },
            'reporter' => { 'name' => 'name' },
            'assignee' => { 'name' => 'different name' },
            'points_field' => 4,
            'timeoriginalestimate' => 4
          }
        end

        it { is_expected.to be true }
      end
    end

    context 'different points' do
      before do
        allow(jira_issue).to receive(:fields) do
          {
            'summary' => 'summary',
            'description' => 'description',
            'issuetype' => { 'id' => 2 },
            'reporter' => { 'name' => 'name' },
            'assignee' => { 'name' => 'different name' },
            'points_field' => 3,
            'timeoriginalestimate' => 4
          }
        end
      end

      it { is_expected.to be true }
    end
  end
end
