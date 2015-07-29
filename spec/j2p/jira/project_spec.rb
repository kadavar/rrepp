require 'rails_helper'

describe JiraToPivotal::Jira::Project do
  before do
    allow_any_instance_of(JiraToPivotal::Jira::Project).
      to receive(:build_api_client).and_return({})
    allow_any_instance_of(JiraToPivotal::Jira::Project).
      to receive(:issue_custom_fields).and_return({})
  end

  let!(:project) { JiraToPivotal::Jira::Project.new({}) }
  let(:story) { double 'story' }
  let!(:issue) { double 'issue' }
  let!(:stories) do
    temp = []
    (1..10).each do
      allow(story).to receive(:to_jira) { {} }
      allow(story).to receive(:assign_to_jira_issue) { {} }
      temp << story
    end
    temp
  end

  before do
    jira_logger = double create_issue_log: true
    logger = double jira_logger: jira_logger

    allow_any_instance_of(JiraToPivotal::Jira::Project).
      to receive(:logger).and_return(logger)

    allow_any_instance_of(JiraToPivotal::Jira::Project).
      to receive(:url).and_return('')
  end

  describe '#create_tasks!' do
    before do
      allow(issue).to receive(:save!) { true }
      allow(issue).to receive(:update_status!) {}
      allow(issue).to receive(:create_notes!) {}
      allow(issue).to receive(:issue) { double key: 1 }

      allow(project).to receive(:build_issue) { [issue, {}] }
    end

    it 'should create ten issues' do
      expect(project).to receive(:logger).exactly(10).times

      project.create_tasks!(stories)
    end

    describe 'with jira custom fields error' do
      before do
        error_story = double 'error_story'
        allow(error_story).to receive(:to_jira) { false }
        allow(error_story).to receive(:assign_to_jira_issue) { {} }

        stories << error_story
      end

      it 'should create only 10 stories' do
        expect(project).to receive(:logger).exactly(10).times

        project.create_tasks!(stories)
      end
    end

    describe 'with issue save error' do
      before do
        allow(issue).to receive(:save!) { false }
      end

      it 'shouldnt create any stories' do
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

    it 'should update all stories if correct ids present' do
      allow(project).to receive(:check_deleted_issues_in_jira) { [[], ['ID!']] }

      expect(project).to receive(:update_issue!).exactly(10).times

      project.update_tasks!(stories)
    end

    it 'should not update stories if there is no correct jira ids' do
      allow(project).to receive(:check_deleted_issues_in_jira) { [[], []] }

      expect(project).to receive(:update_issue!).exactly(0).times

      project.update_tasks!(stories)
    end
  end

  describe '#create_sub_task_for_invosed_issues!' do
    before do
      story_vith_url = double url: 'url'
      allow(story).to receive(:story) { story_vith_url }

      allow(project).to receive(:find_issues) { [issue] }
    end

    describe 'without story urls' do
      before do
        stories.clear
      end

      it 'should not prepare and create sub task' do
        expect(project).to receive(:prepare_and_create_sub_task!).exactly(0).times

        project.create_sub_task_for_invosed_issues!(stories)
      end
    end

    describe 'with story urls' do
      it 'should prepare and  create sub task' do
        expect(project).to receive(:prepare_and_create_sub_task!).exactly(1).times

        project.create_sub_task_for_invosed_issues!(stories)
      end
    end
  end

  describe '#prepare_and_create_sub_task!' do
    before do
      invoced_issue_log = double invoced_issue_log: true
      logger = double jira_logger: invoced_issue_log

      allow_any_instance_of(JiraToPivotal::Jira::Project).
        to receive(:logger).and_return(logger)

      allow(project).to receive(:jira_pivotal_field) { 'pivotal_field' }
      allow(issue).to receive(:pivotal_field) { 'field' }
      allow(story).to receive(:url) { 'no' }
    end

    it 'didnt creates subtask if there is no jira field' do
      expect(project).to receive(:create_sub_task!).exactly(0).times

      project.prepare_and_create_sub_task!(issue, stories)
    end

    describe 'with jira field and without subtask' do
      before do
        allow(project).to receive(:create_sub_task!) { false }
        allow(story).to receive(:url) { 'field' }
      end

      it 'didnt assigns to jira issue if subtask wasnt created' do
        expect(story).to receive(:assign_to_jira_issue).exactly(0).times

        project.prepare_and_create_sub_task!(issue, stories)
      end
    end

    describe 'with jira field and with subtask' do
      before do
        allow(project).to receive(:create_sub_task!) { double key: 'key' }
        allow(project).to receive(:build_issue) { [[], []] }
        allow(project).to receive(:url) { '' }

        allow(story).to receive(:url) { 'field' }
        allow(story).to receive(:assign_to_jira_issue) { {} }
      end

      it 'should delete created story from stories' do
        expect(stories).to receive(:delete).exactly(1).times

        project.prepare_and_create_sub_task!(issue, stories)
      end
    end
  end

  describe '#update_issue!' do
    let!(:jira_issues) { double 'jira issues' }

    before do
      update_issue_log = double update_issue_log: true
      logger = double jira_logger: update_issue_log

      allow_any_instance_of(JiraToPivotal::Jira::Project).
        to receive(:logger).and_return(logger)

      allow(project).to receive(:select_task) { nil }
      allow(project).to receive(:build_issue) { [issue, []] }

      allow(story).to receive(:to_jira) { false }
    end

    it 'should return if there is no jira issue' do
      expect(project).to receive(:build_issue).exactly(0).times

      project.update_issue!(story, jira_issues)
    end

    describe 'with jira issue' do
      before { allow(project).to receive(:select_task) { double 'jira issue' } }

      it 'should return if story didnt cnverted to jira' do
        expect(project).to receive(:build_issue).exactly(0).times

        project.update_issue!(story, jira_issues)
      end
    end

    describe 'with jira issue and converted jira issue' do
      before do
        allow(project).to receive(:select_task) { double 'jira issue' }
        allow(story).to receive(:to_jira) { double 'story to jira' }
      end

      describe 'with main attributes difference' do
        before do
          allow(project).to receive(:difference_checker) {
            double main_attrs_difference?: true
          }
        end

        it 'should be false if issue cant save' do
          allow(issue).to receive(:save!) { false }

          expect(project.update_issue!(story, jira_issues)).to eq(false)
        end

        it 'should be true if issue can save' do
          allow(issue).to receive(:save!) { true }

          expect(project.update_issue!(story, jira_issues)).to eq(true)
        end
      end

      describe 'without main attributes difference' do
        before do
          allow(project).to receive(:difference_checker) {
            double main_attrs_difference?: false
          }
        end

        it 'should be true' do
          expect(project.update_issue!(story, jira_issues)).to eq(true)
        end
      end
    end
  end

  describe '#check_deleted_issues_in_jira' do
    let!(:pivotal_jira_ids) { [] }
    let!(:jira_issues) do
      issues = []

      (1..4).each do |counter|
        status =
          if counter.even?
            double 'status', name: 'Invoiced'
          else
            double 'status', name: 'Other'
          end

        current_issue = double 'issue', status: status

        allow(current_issue).to receive(:key) { "id#{counter}" }

        issues << current_issue
      end

      issues
    end

    it 'should return empty array if pivotal jira ids empty' do
      expect(project.send(:check_deleted_issues_in_jira,
                          pivotal_jira_ids).present?).to eq(true)
    end

    describe 'with non empty pivotal jira ids' do
      before do
        (1..4).each do |counter|
          pivotal_jira_ids << "id#{counter}"
        end

        allow(project).to receive(:find_exists_jira_issues) { jira_issues }
      end

      it 'should return 2 correct and 2 incorrect ids' do
        returned_ids = project.send(:check_deleted_issues_in_jira,
                                    pivotal_jira_ids)

        expect(returned_ids[0].count).to eq(2)
        expect(returned_ids[1].count).to eq(2)
      end
    end
  end
end
