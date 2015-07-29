require 'rails_helper'

describe JiraToPivotal::DifferenceChecker do
  let!(:client) { double 'client', user_permissions: Hash.new { |hsh, key| hsh[key] = {} } }
  let!(:config) do
    { custom_fields: { 'field_id' => 'Story Points' },
      'jira_custom_fields' => { 'pivotal_points' => 'Story Points' } }
  end
  let!(:difference_checker) { JiraToPivotal::DifferenceChecker.new(client, config) }
  let!(:params) { Hash.new }

  describe '#task_type?' do
    describe 'subtask true' do
      before { params[:j2p_issue] = double 'j2p_issue', subtask?: true }

      it 'must return false' do
        expect(difference_checker.send(:task_type?, params)).to eq(false)
      end
    end

    describe 'subtask false' do
      before { params[:j2p_issue] = double 'j2p_issue', subtask?: false }

      describe 'with similar ids' do
        before do
          params[:story_attrs] = { 'fields' => { 'issuetype' => { 'id' => 2 } } }
          params[:jira_issue] = double 'jira_issue',
                                       fields: { 'issuetype' => { 'id' => 2 } }
        end

        it 'must returm false' do
          expect(difference_checker.send(:task_type?, params)).to eq(false)
        end
      end

      describe 'with different ids' do
        before do
          params[:story_attrs] = { 'fields' => { 'issuetype' => { 'id' => 2 } } }
          params[:jira_issue] = double 'jira_issue',
                                       fields: { 'issuetype' => { 'id' => 3 } }
        end

        it 'must return true' do
          expect(difference_checker.send(:task_type?, params)).to eq(true)
        end
      end
    end
  end

  describe '#estimates?' do
    describe 'with incorrect issue type' do
      before { allow(difference_checker).to receive(:incorrect_issue_type?) { true } }

      it 'must return false' do
        expect(difference_checker.send(:estimates?, params)).to eq(false)
      end
    end

    describe 'with correct issue type' do
      before { allow(difference_checker).to receive(:incorrect_issue_type?) { false } }

      describe 'with similar estimates' do
        before do
          params[:story_attrs] = { 'fields' => { 'field_id' => 4 } }
          params[:jira_issue] = double 'jira_issue',
                                       fields: { 'field_id' => 4 }
        end

        it 'must return false with non empty estimate' do
          allow(difference_checker).to receive(:empty_estimate?) { false }
          expect(difference_checker.send(:estimates?, params)).to eq(false)
        end

        it 'must return true with empty estimates' do
          allow(difference_checker).to receive(:empty_estimate?) { true }
          expect(difference_checker.send(:estimates?, params)).to eq(true)
        end
      end

      describe 'with different estimates' do
        before do
          params[:story_attrs] = { 'fields' => { 'field_id' => 4 } }
          params[:jira_issue] = double 'jira_issue',
                                       fields: { 'field_id' => 2 }
        end

        it 'must return true with non empty estimate' do
          allow(difference_checker).to receive(:empty_estimate?) { false }

          expect(difference_checker.send(:estimates?, params)).to eq(true)
        end

        it 'must return false with empty estimates' do
          allow(difference_checker).to receive(:empty_estimate?) { true }

          expect(difference_checker.send(:estimates?, params)).to eq(true)
        end
      end
    end
  end

  describe '#incorrect_issue_type?' do
    let!(:j2p_issue) { double 'j2p_issue' }
    before do
      allow(j2p_issue).to receive(:bug?) { false }
      allow(j2p_issue).to receive(:chore?) { false }
      allow(j2p_issue).to receive(:subtask?) { false }
      params[:j2p_issue] = j2p_issue
    end

    it 'must return false if all issues false' do
      expect(difference_checker.send(:incorrect_issue_type?, params)).to eq(false)
    end

    it 'must return true if bug incorrect' do
      allow(j2p_issue).to receive(:bug?) { true }

      expect(difference_checker.send(:incorrect_issue_type?, params)).to eq(true)
    end

    it 'must return true if chore incorrect' do
      allow(j2p_issue).to receive(:chore?) { true }

      expect(difference_checker.send(:incorrect_issue_type?, params)).to eq(true)
    end

    it 'must return true if subtask incorrect' do
      allow(j2p_issue).to receive(:subtask?) { true }

      expect(difference_checker.send(:incorrect_issue_type?, params)).to eq(true)
    end
  end

  describe 'reporter?' do
    describe 'without ability to modify reporter' do
      before { allow(difference_checker).to receive(:user_permissions) { double modify_reporter?: false } }

      it 'must return false' do
        expect(difference_checker.send(:reporter?, params)).to eq(false)
      end
    end

    describe 'with ability to modify reporter' do
      before { allow(difference_checker).to receive(:user_permissions) { double modify_reporter?: true } }

      describe 'with jira and pivotal reporter exists' do
        before do
          allow(difference_checker).to receive(:story_reporter) { { 'name' => 'John' } }
          allow(difference_checker).to receive(:jira_reporter) { { 'name' => 'John' } }
        end

        it 'must return false if names similar' do
          expect(difference_checker.send(:reporter?, params)).to eq(false)
        end

        it 'must return true if different names' do
          allow(difference_checker).to receive(:jira_reporter) { { 'name' => 'Mike' } }

          expect(difference_checker.send(:reporter?, params)).to eq(true)
        end
      end

      describe 'without reporters' do
        before do
          allow(difference_checker).to receive(:story_reporter) { nil }
          allow(difference_checker).to receive(:jira_reporter) { nil }
        end

        it 'should be false without any reporters' do
          expect(difference_checker.send(:reporter?, params)).to eq(nil)
        end

        it 'should be true with pivotel and without jira reporter' do
          allow(difference_checker).to receive(:story_reporter) { { 'name' => 'John' } }

          expect(difference_checker.send(:reporter?, params)).to eq(true)
        end

        it 'should be false with jira and without pivotal' do
          allow(difference_checker).to receive(:jira_reporter) { { 'name' => 'John' } }

          expect(difference_checker.send(:reporter?, params)).to eq(nil)
        end
      end
    end
  end

  describe '#assignee?' do
    describe 'without ability to assign issue' do
      before { allow(difference_checker).to receive(:user_permissions) { double assign_issue?: false } }

      it 'must return false' do
        expect(difference_checker.send(:asignee?, params)).to eq(false)
      end
    end

    describe 'with ability to assign issue' do
      before { allow(difference_checker).to receive(:user_permissions) { double assign_issue?: true } }

      describe 'with story assignee and jira assignee' do
        before do
          allow(difference_checker).to receive(:story_assignee) { { 'name' => 'John' } }
          allow(difference_checker).to receive(:jira_assignee) { { 'name' => 'John' } }
        end

        it 'should return false if names are similar' do
          expect(difference_checker.send(:asignee?, params)).to eq(false)
        end

        it 'should be true if names are different' do
          allow(difference_checker).to receive(:jira_assignee) { { 'name' => 'Mike' } }

          expect(difference_checker.send(:asignee?, params)).to eq(true)
        end
      end

      describe 'without assignees' do
        before do
          allow(difference_checker).to receive(:story_assignee) { nil }
          allow(difference_checker).to receive(:jira_assignee) { nil }
        end

        it 'should be false without any reporters' do
          expect(difference_checker.send(:asignee?, params)).to eq(nil)
        end

        it 'should be true with pivotel and without jira reporter' do
          allow(difference_checker).to receive(:story_assignee) { { 'name' => 'John' } }

          expect(difference_checker.send(:asignee?, params)).to eq(true)
        end

        it 'should be false with jira and without pivotal' do
          allow(difference_checker).to receive(:jira_assignee) { { 'name' => 'John' } }

          expect(difference_checker.send(:asignee?, params)).to eq(nil)
        end
      end
    end
  end

  describe '#status?' do
    let!(:story) { double 'story' }
    let!(:jira_issue) { double 'jira_issue' }

    describe 'with similar statuses' do
      before do
        allow(story).to receive(:current_story_status_to_issue_status) { 'open' }
        allow(jira_issue).to receive(:fields) { { 'status' => { 'name' => 'open' } } }
      end

      it 'should return false' do
        expect(difference_checker.send(:status?, jira_issue, story)).to eq(false)
      end
    end

    describe 'with different statuses' do
      before do
        allow(story).to receive(:current_story_status_to_issue_status) { 'open' }
        allow(jira_issue).to receive(:fields) { { 'status' => { 'name' => 'closed' } } }
      end

      it 'should return true' do
        expect(difference_checker.send(:status?, jira_issue, story)).to eq(true)
      end
    end
  end

  describe '#difference_between_pivotal_jira?' do
    before do
      allow(difference_checker).to receive(:summary?) { false }
      allow(difference_checker).to receive(:description?) { false }
      allow(difference_checker).to receive(:task_type?) { false }
      allow(difference_checker).to receive(:reporter?) { false }
      allow(difference_checker).to receive(:asignee?) { false }
      allow(difference_checker).to receive(:estimates?) { false }
    end

    it 'should be false when all checks false' do
      expect(difference_checker.send(:difference_between_pivotal_jira?, params)).to eq(false)
    end

    it 'should be true when summary true' do
      allow(difference_checker).to receive(:summary?) { true }

      expect(difference_checker.send(:difference_between_pivotal_jira?, params)).to eq(true)
    end

    it 'should be true when description true' do
      allow(difference_checker).to receive(:description?) { true }

      expect(difference_checker.send(:difference_between_pivotal_jira?, params)).to eq(true)
    end

    it 'should be true when task_type true' do
      allow(difference_checker).to receive(:task_type?) { true }

      expect(difference_checker.send(:difference_between_pivotal_jira?, params)).to eq(true)
    end

    it 'should be true when reporter true' do
      allow(difference_checker).to receive(:reporter?) { true }

      expect(difference_checker.send(:difference_between_pivotal_jira?, params)).to eq(true)
    end

    it 'should be true when asignee true' do
      allow(difference_checker).to receive(:asignee?) { true }

      expect(difference_checker.send(:difference_between_pivotal_jira?, params)).to eq(true)
    end

    it 'should be true when estimates true' do
      allow(difference_checker).to receive(:estimates?) { true }

      expect(difference_checker.send(:difference_between_pivotal_jira?, params)).to eq(true)
    end
  end
end
