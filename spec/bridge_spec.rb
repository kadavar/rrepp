require 'rails_helper'

describe SyncWorker do
  let(:hash) do
    {
      tracker_project_id: '312',
      jira_login: 'test',
      jira_host: 'jira_host',
      jira_uri_scheme: 'HTTP',
      jira_port: '80',
      jira_project: 'JPT',
      jira_filter: '12000',
      retry_count: '2',
      script_first_start: '2',
      script_repeat_time: '5m',
      jira_custom_fields:
        { pivotal_points: 'Story Points',
          pivotal_url: 'Pivotal Tracker URL' },
      jira_issue_types:
        { bug: '1',
          feature: '2',
          chore: '9' },
      jira_password: 'password',
      tracker_token: 'token'
    }
  end

  let(:inner_jira_project) { double 'inner_jira_project' }
  let(:updated_tasks) { double 'updated_tasks' }
  let(:unsynchronized_issues) { double 'unsynchronized_issues' }
  let(:mapped_unsynchronized_issues) { double 'mapped_unsynchronized_issues' }
  before do
    allow(mapped_unsynchronized_issues).to receive(:reduce) { mapped_unsynchronized_issues }
  end
  let(:issue) { double 'issue' }
  let(:assigned_issue) { double 'assigned_issue' }
  before do
    allow(issue).to receive(:send) { 'url' }
    allow(issue).to receive(:key) { 'url' }
    allow(issue).to receive(:issue) { issue }
  end
  before do
    allow(unsynchronized_issues).to receive(:[]).with(:to_update) { [unsynchronized_issues] }
    allow(unsynchronized_issues).to receive(:[]).with(:to_create) { [unsynchronized_issues] }
    allow(unsynchronized_issues).to receive(:map) { mapped_unsynchronized_issues }
    allow(unsynchronized_issues).to receive(:key) { 'url' }
    allow(unsynchronized_issues).to receive(:issue) { issue }

  end

  before do
    allow_any_instance_of(JiraToPivotal::Jira::Project).to receive(:issue_custom_fields) { {} }
    allow_any_instance_of(JiraToPivotal::Jira::Project).to receive(:project) {  inner_jira_project  }
    allow_any_instance_of(JiraToPivotal::Jira::Project).to receive(:update_tasks!) {  updated_tasks  }
    allow_any_instance_of(JiraToPivotal::Jira::Project).to receive(:unsynchronized_issues) { unsynchronized_issues  }
    allow_any_instance_of(JiraToPivotal::Jira::Project).to receive(:create_sub_task_for_invoiced_issues!) { 'create_sub_tasks' }
    allow_any_instance_of(JiraToPivotal::Jira::Project).to receive(:create_tasks!) { 'create_tasks!' }
  end

  let(:inner_pivotal_project) { double 'inner_pivotal_project' }
  before do
    allow(inner_pivotal_project).to receive(:project) { inner_pivotal_project }
    allow(TrackerApi::Client).to receive(:new) { inner_pivotal_project }
  end
  let(:to_update_stories) { double 'to_update_stories' }
  let(:jira_id_map) { double 'jira_id_map' }
  before do
    allow(to_update_stories).to receive(:map) { to_update_stories }
    allow(to_update_stories).to receive(:join).with(',') { jira_id_map }
  end
  let(:story) { double 'story' }
  before do
    allow(story).to receive(:url) { 'url' }
    allow(story).to receive(:assign_to_jira_issue) { 'assigned_story' }
  end
  let(:to_create_stories) { double 'to_create_stories' }
  before do
    allow(to_create_stories).to receive(:story) { story }
    allow(to_create_stories).to receive(:url) { 'url' }
    allow(to_create_stories).to receive(:jira_issue_id) { 'jira_issue_id' }
    allow(to_create_stories).to receive(:assign_to_jira_issue) { assigned_issue }
  end

  before do
    allow_any_instance_of(JiraToPivotal::Pivotal::Project).to receive(:load_to_create_stories) { [to_create_stories] }
    allow_any_instance_of(JiraToPivotal::Pivotal::Project).to receive(:load_to_update_stories) { to_update_stories }
    allow_any_instance_of(JiraToPivotal::Pivotal::Project).to receive(:create_tasks!) { 'create_task' }
  end

  let(:hash_name) { SecureRandom.random_bytes(64) }
  let(:project) { double 'project' }
  let(:worker) { SyncWorker.new }
  let(:bridge) { JiraToPivotal::Bridge.new(hash_name) }
  before do
    crypt = ActiveSupport::MessageEncryptor.new(hash_name)
    encrypted_hash = crypt.encrypt_and_sign(hash.to_json)
    Sidekiq.redis { |connection| connection.set(hash_name,encrypted_hash) }
  end

  let(:logger) { double 'logger' }
  let(:jira_logger) { double 'jira_logger' }
  before do
    allow(JiraToPivotal::ScriptLogger).to receive(:new) { logger }
  end
  before do
    allow(jira_logger).to receive(:update_jira_pivotal_connection_log) { 'update_j2p_connection_log' }
  end
  before do
    allow(logger).to receive(:logger) { logger }
    allow(logger).to receive(:error) { 'log.error' }
    allow(logger).to receive(:update_config) { 'log.update_config' }
    allow(logger).to receive(:error_log) { 'log.error_log' }
    allow(logger).to receive(:jira_logger) { jira_logger }
  end

  before { bridge.instance_variable_set(:@logger,logger) }
  after { Sidekiq.redis { |connection| connection.del(hash_name) } }

  describe '#sync!' do
    subject { worker.perform(project,hash_name) }
    context 'when check_projects return nil' do
    let(:inner_jira_project) { nil }
    let(:inner_pivotal_project) { nil }

    it { is_expected.to eq nil }
    end
    context 'when check_projects is true' do
      it { is_expected.to eq 'create_tasks!' }
    end
  end
  describe '#from_jira_to_pivotal!' do
    subject { bridge.from_jira_to_pivotal! }
    it { is_expected.to eq 'create_task' }
  end
end
