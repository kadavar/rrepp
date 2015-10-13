require 'rails_helper'

describe JiraToPivotal::Jira::SubtasksHandler do
  before { allow_any_instance_of(JiraToPivotal::Jira::Project).to receive(:build_api_client).and_return({}) }

  let(:issue_custom_fields) { { 'jira_url' => 'url' } }

  before { allow(issue_custom_fields).to receive(:jira_url) { 'url' } }

  before { allow_any_instance_of(JiraToPivotal::Jira::Project).to receive(:issue_custom_fields).and_return(issue_custom_fields) }

  let(:config) { JiraToPivotal::Config.new({ 'jira_uri_scheme' => 'https', 'jira_host' => 'localhost' }) }
  let!(:jira_project) { JiraToPivotal::Jira::Project.new(config) }
  let(:logger) { double 'logger' }
  let(:jira_logger) { double 'jira_logger' }
  let(:inner_jira_project) { double 'inner jira project' }
  let(:subtasks_handler) { JiraToPivotal::Jira::SubtasksHandler.new(jira_project: jira_project, project_name: 'test', config: config) }

  before do
    allow(jira_project).to receive(:project) { inner_jira_project }
    allow(jira_project).to receive(:options_for_issue) { {} }
  end

  before do
    allow(subtasks_handler).to receive(:logger) { logger }
  end

  before do
    allow(jira_logger).to receive(:create_sub_task_log) {}
    allow(jira_logger).to receive(:invoced_issue_log) {}
  end

  before { allow(inner_jira_project).to receive(:id) { '1' } }
  before { allow(logger). to receive(:jira_logger) { jira_logger } }

  describe '#create_sub_tasks!' do
    context 'empty stories' do
      specify 'returns nil' do
        expect(subtasks_handler.create_sub_tasks!({})).to be nil
      end
    end

    context 'with story' do
      let(:stories) { [story] }
      let(:story) { double 'story' }
      let(:issue) { double 'issue' }
      let(:inner_story) { double 'inner story' }

      before { allow(story).to receive(:story) { inner_story } }
      before { allow(inner_story).to receive(:url) { 'url' } }

      before do
        allow_any_instance_of(JiraToPivotal::Jira::Project).to receive(:map_jira_ids_for_search).and_return(true)
        allow_any_instance_of(JiraToPivotal::Jira::Project).to receive(:find_issues).and_return([issue])
      end

      before { allow(subtasks_handler).to receive (:jira_project) { jira_project } }

      describe 'prepare and create sub task invocation' do
        before { allow(subtasks_handler).to receive(:prepare_and_create_sub_task!) {} }

        specify 'invokes prepare and create subtask' do
          expect(subtasks_handler).to receive(:prepare_and_create_sub_task!).exactly(1).times

          subtasks_handler.create_sub_tasks!(stories)
        end
      end

      describe 'creates sub task' do
        let(:fields) { { 'summary' => 'summary' } }
        let(:jira_project_client) { double 'jira project client' }
        let(:jira_client_issue) { double 'jira_client_issue' }

        before do
          allow(story).to receive(:url) { 'url' }
          allow(story).to receive(:assign_to_jira_issue) {}
        end

        before do
          allow_any_instance_of(JiraToPivotal::Jira::Issue).to receive(:save!) { true }
          allow_any_instance_of(JiraToPivotal::Jira::Issue).to receive(:key) {}
        end

        before do
          allow(issue).to receive(:url) { 'url' }
          allow(issue).to receive(:fields) { fields }
          allow(issue).to receive(:key) {}
        end

        before do
          allow(jira_project).to receive(:jira_pivotal_field) { 'url' }
          allow(subtasks_handler).to receive(:parent_id_for) { '1' }
          allow(subtasks_handler).to receive(:url) { 'url' }
        end

        before { allow(jira_project).to receive(:client) { jira_project_client } }
        before { allow(jira_project_client).to receive(:Issue) { jira_client_issue } }
        before { allow(jira_client_issue).to receive(:build) { issue } }

        specify 'creates subask' do
          expect_any_instance_of(JiraToPivotal::Jira::Issue).to receive(:save!) do |issue, attrs, config|
            expect(attrs['fields']['project']['id']).to eq '1'
          end

          subtasks_handler.create_sub_tasks!(stories)

          expect(stories.count).to eq 0
        end
      end
    end
  end
end
