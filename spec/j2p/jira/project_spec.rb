require 'rails_helper'
include JiraProjectsHelper
describe JiraToPivotal::Jira::Project do
  before do
  #  allow_any_instance_of(JiraToPivotal::Jira::Project).to receive(:build_api_client).and_return({})
    allow_any_instance_of(JiraToPivotal::Jira::Project).to receive(:issue_custom_fields).and_return({})
  end

  let(:story) { double 'story' }
  let(:issue) { double 'issue' }
  let(:stories) { [story] }
  let(:jira_logger) { double create_issue_log: true }
  let(:logger) { double 'logger' }
  let(:init_conf) { { 'script_repeat_time' => '2',
                      'retry_count' => '2',
                      'jira_login' => 'login',
                      'jira_password' => 'passw',
                      'jira_url' => 'j_url',
                      'jira_project' => 'jira_project',
                      'iira_custom_fields' =>
                        { 'pivotal_url' => 'pivotal_url' } } }

  let(:conf) { JiraToPivotal::Config.new(init_conf) }
  let!(:project) { JiraToPivotal::Jira::Project.new(conf) }
  let(:client) { double 'client' }
  let(:inner_project) { double 'inner project'}

  before do
    allow(conf).to receive(:airbrake_message_parameters) {}
    allow(project).to receive(:url) { 'jira_url' }
  end

  before { project.build_api_client }
  before do
    #JiraToPivotal::Jira::Project.build_api_client
    allow(logger).to receive(:jira_logger) { jira_logger }
    allow(logger).to receive(:error_log) {}
  end

  before do
    allow_any_instance_of(JiraToPivotal::Jira::Project).to receive(:logger).and_return(logger)
    allow_any_instance_of(JiraToPivotal::Jira::Project).to receive(:url).and_return('')
  end

  before do
    allow(story).to receive(:to_jira) { {} }
    allow(story).to receive(:assign_to_jira_issue) { {} }
  end

  before { allow(Airbrake).to receive(:notify_or_ignore) {} }
  before { project.instance_variable_set(:@config, conf) }

  before do
    allow(project).to receive(:client) { client }
    allow(project).to receive(:project) { inner_project }
  end

  describe '#create_tasks!' do
    before do
      allow(issue).to receive(:save!) { true }
      allow(issue).to receive(:update_status!) {}
      allow(issue).to receive(:create_notes!) {}
      allow(issue).to receive(:issue) { double key: 1 }
    end

    before { allow(project).to receive(:build_issue) { [issue, {}] } }

    it 'creates issue' do
      expect(project).to receive(:logger).exactly(1).times

      project.create_tasks!(stories)
    end

    context 'with jira custom fields error' do
      let(:error_story) { error_story = double 'error_story' }

      before do
        allow(error_story).to receive(:to_jira) { false }
        allow(error_story).to receive(:assign_to_jira_issue) { {} }
      end

      before { stories << error_story }

      it 'creates stories' do
        expect(project).to receive(:logger).exactly(1).times

        project.create_tasks!(stories)
      end
    end

    context 'with issue save error' do
      before { allow(issue).to receive(:save!) { false } }

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
    end

    before { allow(story).to receive(:jira_issue_id) { {} } }

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

  describe '#create_sub_task_for_invoiced_issues!' do
    let(:story_vith_url) { double 'url' }

    before { allow(story_vith_url).to receive(:url) { 'url' } }
    before { allow(story).to receive(:story) { story_vith_url } }
    before { allow(project).to receive(:find_issues) { [issue] } }

    context 'call subtask handler' do
      it 'creates sub task' do
        expect_any_instance_of(JiraToPivotal::Jira::SubtasksHandler).to receive(:create_sub_tasks!).with(stories).exactly(1).times

        project.create_sub_task_for_invoiced_issues!(stories)
      end
    end
  end

  describe '#update_issue!' do
    subject { project.update_issue!(story, jira_issues) }

    let(:jira_issues) { double 'jira issues' }
    let(:update_issue_log) { double 'update_issue_log' }
    let(:logger) { double 'logger' }

    before { allow(update_issue_log).to receive(:update_issue_log) { true } }
    before { allow(logger).to receive(:jira_logger) { update_issue_log } }
    before { allow_any_instance_of(JiraToPivotal::Jira::Project).to receive(:logger).and_return(logger) }

    before do
      allow(project).to receive(:select_task) { nil }
      allow(project).to receive(:build_issue) { [issue, []] }
    end

    before { allow(story).to receive(:to_jira) { false } }

    context 'without no jira issue' do
      it { is_expected.to be nil }
    end

    context 'with jira issue' do
      before { allow(project).to receive(:select_task) { {} } }

      it { is_expected.to be nil }
    end

    describe 'with jira issue and converted jira issue' do
      let(:difference_checker) { double 'difference_checker' }

      before { allow(project).to receive(:difference_checker) { difference_checker } }

      before do
        allow(project).to receive(:select_task) { double 'jira issue' }
        allow(story).to receive(:to_jira) { double 'story to jira' }
      end

      describe 'with main attributes difference' do
        before { allow(difference_checker).to receive(:main_attrs_difference?) { true } }

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
        before { allow(difference_checker).to receive(:main_attrs_difference?) { false } }

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

  describe '#project' do
    before { allow(project).to receive(:project).and_call_original }
    subject { project.project }
    context 'with error' do
      let(:error) { double 'error' }
      before do
        allow(error).to receive(:message) { 'message' }
        allow(error).to receive(:code) { 'code' }
      end

      before { allow(project).to receive(:client) { fail JIRA::HTTPError.new(error), 'message' } }

      it 'retries 2 times and raises exception' do
        expect(project).to receive(:client).exactly(2).times
        expect { project.project }.to raise_exception JIRA::HTTPError
      end
    end
    context 'with Errno::ETIMEDOUT' do
      let(:error) { double 'error' }
      before do
        allow_any_instance_of(JiraToPivotal::Retryable).to receive(:retryable) { fail Errno::ETIMEDOUT }
      end
      it { is_expected.to eq false }
    end

  end

  describe '#update_config' do
    let(:options)  { { new: 'option' } }
    subject { project.update_config(options) }

    context 'when options is empty' do
      let(:opt)  { { } }
      it { expect(project.update_config(opt)).to eq init_conf }
    end
    context 'when options is not empty' do
      it { is_expected.to include options }
    end
  end

  describe '#find_issues' do
    context 'with Jira::HTTPError' do
      let(:error) { double 'error' }

      before do
        allow(error).to receive(:message) { 'message' }
        allow(error).to receive(:code) { 'code' }
      end

      before { allow(JIRA::Resource::Issue).to receive(:jql) { fail JIRA::HTTPError.new(error), 'message' } }

      it 'retries 2 times, and returns empty array' do
        expect(JIRA::Resource::Issue).to receive(:jql).exactly(2).times

        expect(project.find_issues({}, [])).to eq []
      end
    end

    context 'with SocketError' do
      before { allow(JIRA::Resource::Issue).to receive(:jql) { fail SocketError, 'message' } }

      it 'retries 2 times, and returns empty array' do
        expect(JIRA::Resource::Issue).to receive(:jql).exactly(2).times

        expect(project.find_issues({}, [])).to eq []
      end
    end
  end

  describe '#differnce_checker' do
    subject { project.difference_checker }
    context ' when its working ' do
      before { allow(JiraToPivotal::DifferenceChecker).to receive(:new) { 'its working' } }
      it { is_expected.to eq 'its working' }
    end
  end

  describe '#issues' do
    before { init_conf['jira_filter'] = true }

    context 'with Jira::HTTPError' do
      let(:error) { double 'error' }

      before do
        allow(error).to receive(:message) { 'message' }
        allow(error).to receive(:code) { 'code' }
      end

      before { allow(inner_project).to receive(:issues_by_filter) { fail JIRA::HTTPError.new(error), 'message' } }

      it 'retries 2 times, and returns nil' do
        expect(inner_project).to receive(:issues_by_filter).exactly(2).times

        expect(project.send :issues, 1).to eq nil
      end
    end

    context 'with SocketError' do
      before { allow(inner_project).to receive(:issues_by_filter) { fail SocketError, 'message' } }

      it 'retries 2 times, and returns nil' do
        expect(inner_project).to receive(:issues_by_filter).exactly(2).times

        expect(project.send :issues, 1).to eq nil
      end
    end
  end

  describe '#issue_custom_fields' do
    before do
      allow_any_instance_of(JiraToPivotal::Jira::Project).to receive(:issue_custom_fields).and_call_original
    end
    before { allow(inner_project).to receive(:issue_with_name_expand) { issue } }
    let(:issue) { double 'issue' }
    subject { project.issue_custom_fields }

    context 'when names is present' do
      before { allow(issue).to receive(:names) { 'names' } }
      it { is_expected.to eq 'names' }
    end

    context 'when names not present' do
      before { allow(issue).to receive(:names) { } }
      before { allow(logger).to receive(:attrs_log) { } }
      it { expect { project.issue_custom_fields }.to raise_error RuntimeError }
    end
  end

  describe '#next_issues' do
    let(:issues) { double 'issues' }
    before { allow(inner_project).to receive(:issues).and_return(issues) }
    subject { project.next_issues }

    context 'when issues list is present' do
      it { is_expected.to eq issues }
      specify 'change @start_index by 50' do
        project.next_issues
        expect(project.instance_variable_get(:@start_index)).to eq 50
      end
    end

    context ' when issues list is empty' do
      before { allow(inner_project).to receive(:issues).and_return(nil) }
      it { is_expected.to eq [] }
    end
  end

  describe '#select_task' do
    let(:issues) { double 'issues' }
    let(:story) { double 'story' }
    before do
      allow(issues).to receive(:find) { issues }
    end
    subject { project.select_task(issues,story) }
    context 'when return issues' do
      it { is_expected.to eq issues }
    end
  end

  describe '#unsynchronized_issues' do
    subject { project.unsynchronized_issues }
    let(:issue) { double 'issue' }
    let(:fields) { { 'fields'=>{ 'url'=> 'urls' } } }
    let(:con) { { 'jira_custom_fields' => { 'pivotal_url' => 'piv_url' } } }
    before do
      allow(issue).to receive(:fetch).and_return(issue)
      allow(issue).to receive(:issue).and_return(issue)
      allow(issue).to receive(:attrs).and_return(fields)
      allow(project).to receive(:config).and_return(con)
    end
    let(:issues) { Array.new(1,issue) }
    before do
      allow(inner_project).to receive(:issues).and_return(issues)
    end
    context 'do ' do
      it { is_expected.not_to eq nil }
    end
  end
end
