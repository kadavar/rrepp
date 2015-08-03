require 'rails_helper'
include JiraProjectsHelper
describe JiraToPivotal::Jira::Project do
  before do
    allow_any_instance_of(JiraToPivotal::Jira::Project).to receive(:build_api_client).and_return({})
    allow_any_instance_of(JiraToPivotal::Jira::Project).to receive(:issue_custom_fields).and_return({})
  end

  let!(:project) { JiraToPivotal::Jira::Project.new({}) }
  let(:story) { double 'story' }
  let(:issue) { double 'issue' }
  let(:stories) { [story] }

  before do
    jira_logger = double create_issue_log: true
    logger = double jira_logger: jira_logger

    allow_any_instance_of(JiraToPivotal::Jira::Project).to receive(:logger).and_return(logger)
    allow_any_instance_of(JiraToPivotal::Jira::Project).to receive(:url).and_return('')

    allow(story).to receive(:to_jira) { {} }
    allow(story).to receive(:assign_to_jira_issue) { {} }
  end

  describe '#create_tasks!' do
    before do
      allow(issue).to receive(:save!) { true }
      allow(issue).to receive(:update_status!) {}
      allow(issue).to receive(:create_notes!) {}
      allow(issue).to receive(:issue) { double key: 1 }

      allow(project).to receive(:build_issue) { [issue, {}] }
    end

    it 'creates issue' do
      expect(project).to receive(:logger).exactly(1).times

      project.create_tasks!(stories)
    end

    context 'with jira custom fields error' do
      before do
        error_story = double 'error_story'
        allow(error_story).to receive(:to_jira) { false }
        allow(error_story).to receive(:assign_to_jira_issue) { {} }

        stories << error_story
      end

      it 'creates storie' do
        expect(project).to receive(:logger).exactly(1).times

        project.create_tasks!(stories)
      end
    end

    context 'with issue save error' do
      before do
        allow(issue).to receive(:save!) { false }
      end

      it 'didnt creates stories' do
        expect(project).to receive(:logger).exactly(0).times

        project.create_tasks!(stories)
      end
    end
  end

  describe '#update_tasks!' do
    before do
      allow(project).to receive(:remove_jira_id_from_pivotal) { {} }
      allow(project).to receive(:update_issue!) { {} }
      allow(project).to receive(:find_issues) { {} }
      allow(story).to receive(:jira_issue_id) { {} }
    end

    context 'with correct ids' do
      before { allow(project).to receive(:check_deleted_issues_in_jira) { [[], ['ID!']] } }

      it 'updates 1 issue' do
        expect(project).to receive(:update_issue!).exactly(1).times

        project.update_tasks!(stories)
      end
    end

    context 'there is no correct jira ids' do
      before { allow(project).to receive(:check_deleted_issues_in_jira) { [[], []] } }

      it 'doesnt updates issues' do
        expect(project).to receive(:update_issue!).exactly(0).times

        project.update_tasks!(stories)
      end
    end
  end

  describe '#create_sub_task_for_invosed_issues!' do
    before do
      story_vith_url = double 'url'
      allow(story_vith_url).to receive(:url) { 'url' }

      allow(story).to receive(:story) { story_vith_url }

      allow(project).to receive(:find_issues) { [issue] }
    end

    context 'without story urls' do
      before { stories.clear }

      it 'doesnt creates subtasks' do
        expect(project).to receive(:prepare_and_create_sub_task!).exactly(0).times

        project.create_sub_task_for_invosed_issues!(stories)
      end
    end

    context 'with story urls and founded jira issue' do
      it 'creates sub task' do
        expect(project).to receive(:prepare_and_create_sub_task!).exactly(1).times

        project.create_sub_task_for_invosed_issues!(stories)
      end
    end
  end

  describe '#prepare_and_create_sub_task!' do
    subject { project.prepare_and_create_sub_task!(issue, stories) }

    before do
      invoced_issue_log = double 'invoced_issue_log'
      allow(invoced_issue_log).to receive(:invoced_issue_log) { true }

      logger = double 'jira logger'
      allow(logger).to receive(:jira_logger) { invoced_issue_log }

      allow_any_instance_of(JiraToPivotal::Jira::Project).to receive(:logger).and_return(logger)

      allow(project).to receive(:jira_pivotal_field) { 'pivotal_field' }
      allow(issue).to receive(:pivotal_field) { 'field' }
      allow(story).to receive(:url) { 'no' }
    end

    context 'without jira field' do
      it { is_expected.to be false }
    end

    context 'with jira field' do
      before do
        allow(project).to receive(:create_sub_task!) { false }
        allow(story).to receive(:url) { 'field' }
      end

      it { is_expected.to be false }
    end

    context 'with jira field and subtask' do
      before do
        key = double 'key'
        allow(key).to receive(:key) { 'key' }

        allow(project).to receive(:create_sub_task!) { key }
        allow(project).to receive(:build_issue) { [[], []] }
        allow(project).to receive(:url) { '' }

        allow(story).to receive(:url) { 'field' }
        allow(story).to receive(:assign_to_jira_issue) { {} }
      end

      it { is_expected.to be true }
    end
  end

  describe '#update_issue!' do
    subject { project.update_issue!(story, jira_issues) }

    let(:jira_issues) { double 'jira issues' }

    before do
      update_issue_log = double 'update_issue_log'
      allow(update_issue_log).to receive(:update_issue_log) { true }

      logger = double 'logger'
      allow(logger).to receive(:jira_logger) { update_issue_log }

      allow_any_instance_of(JiraToPivotal::Jira::Project).to receive(:logger).and_return(logger)

      allow(project).to receive(:select_task) { nil }
      allow(project).to receive(:build_issue) { [issue, []] }

      allow(story).to receive(:to_jira) { false }
    end

    context 'without no jira issue' do
      it { is_expected.to be nil }
    end

    context 'with jira issue' do
      before { allow(project).to receive(:select_task) { {} } }

      it { is_expected.to be nil }
    end

    describe 'with jira issue and converted jira issue' do
      before do
        allow(project).to receive(:select_task) { double 'jira issue' }
        allow(story).to receive(:to_jira) { double 'story to jira' }
      end

      describe 'with main attributes difference' do
        before do
          difference_checker = double 'difference_checker'
          allow(difference_checker).to receive(:main_attrs_difference?) { true }

          allow(project).to receive(:difference_checker) { difference_checker }
        end

        context 'issue cant save' do
          before { allow(issue).to receive(:save!) { false } }

          it { is_expected.to be false }
        end

        context 'issue can save' do
          before { allow(issue).to receive(:save!) { true } }

          it { is_expected.to be true }
        end
      end

      describe 'without main attributes difference' do
        before do
          difference_checker = double 'difference_checker'
          allow(difference_checker).to receive(:main_attrs_difference?) { false }

          allow(project).to receive(:difference_checker) { difference_checker }
        end

        it { is_expected.to be true }
      end
    end
  end

  describe '#check_deleted_issues_in_jira' do
    subject(:check) { project.send(:check_deleted_issues_in_jira, pivotal_jira_ids) }

    let(:pivotal_jira_ids) { %w( id1 id2 ) }
    let(:jira_issues) { generate_jira_issues }

    context 'pivotal jira ids empty' do
      before { pivotal_jira_ids.clear }

      it 'returns two emty collections' do
        expect(check[0].empty?).to be true
        expect(check[1].empty?).to be true
      end
    end

    context 'non empty pivotal jira ids' do
      before { allow(project).to receive(:find_exists_jira_issues) { jira_issues } }

      it 'returns 1 correct and 1 incorrect ids' do
        expect(check[0].count).to be 1
        expect(check[1].count).to be 1
      end
    end
  end
end
