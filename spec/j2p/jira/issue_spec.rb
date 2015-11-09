require 'rails_helper'

describe JiraToPivotal::Jira::Issue do

  let(:client) { double 'client' }
  let(:project) { create :project }
  let(:issue) { double 'issue' }
  let(:config) { create :config }
  let(:options) do
    { :client => client,
      :project => project,
      :issue => issue,
      :config => config
    }
  end
  let(:e) { double 'e' }
  before do
    allow(e).to receive(:respoonse) { e }
    allow(e).to receive(:body) { 'message' }
    allow(e).to receive(:message) { 'message' }
  end
  let(:story_url) { 'story_url' }
  let(:fields) { {} }
  before { allow(issue).to receive(:fields) { fields } }
  before { allow(config).to receive(:airbrake_message_parameters) { {} } }

  let(:logger) { double 'logger' }
  before do
    allow(logger).to receive(:attrs_log) { 'true' }
    allow(logger).to receive(:error_log) { 'error_log' }
  end

  let(:jira_issue) { JiraToPivotal::Jira::Issue.new(options) }
  let(:comment) { double 'comment' }
  before { allow(comment).to receive(:body) { 'comment_body' } }
  before { allow(JiraToPivotal::ScriptLogger).to receive(:new) { logger } }
  before { allow(issue).to receive(:comments) { [comment] } }
  let(:story) { double 'story' }

  describe '#comments' do
    subject { jira_issue.comments }
    context 'when comments' do
      it { is_expected.to eq [comment] }
    end
    context 'when comments' do
      let(:body) { jira_issue.comment_text }
      let(:comment) { double 'comment' }
      before { allow(comment).to receive(:body) { body } }
      before { allow(issue).to receive(:comments) { [comment] } }

      it { is_expected.to eq [] }
    end
  end

  describe '#attachments' do
    let(:attachment) { double 'attachment' }
    before { allow(issue).to receive(:attachments) { [attachment] } }
    subject { jira_issue.attachments }

    context 'when attachments exist' do
      it { expect(subject.first.attachment).to eq attachment }
      it { expect(subject.first.project).to eq project }
    end

    context 'when attachments not exist' do
      before { allow(issue).to receive(:attachments) { [] } }
      it { is_expected.to eq [] }
    end
  end

  describe '#add_marker_comment' do
    let(:story_url) { 'story_url' }
    let(:new_comment) { double 'new_comment' }
    before { allow(issue).to receive(:comments) { new_comment } }
    before { allow(new_comment).to receive(:build) { new_comment } }
    before { allow(new_comment).to receive(:save) { 'saved' } }

    subject { jira_issue.add_marker_comment(story_url) }

    context 'save created comment ' do
      it { is_expected.to eq 'saved' }
    end
  end

  describe '#save!' do
    let(:config) { { custom_fields:
                         { 'piv_points' => 'points',
                           'piv_url' => 'url' },
                     'jira_custom_fields' =>
                         { 'pivotal_points' => 'piv_points',
                           'pivotal_url' => 'piv_url' } } }
    let(:attrs) { double 'attrs' }
    subject { jira_issue.assign_to_pivotal_issue(story_url, config) }

    context 'when status is closed ' do
      let(:fields) { { 'status' => { 'name' => 'Closed' } } }
      it { is_expected.to eq false }
    end

    describe 'non closed status' do
      let(:fields) { { 'issuetype' => { 'name' => 'name' },
                       'timetracking' => 'originalEstimate',
                       'reporter' => 'reporter' } }
      let(:not_equal_fields) { { 'issuetype' => { 'name' => 'names' },
                                 'timetracking' => 'originalEstimate',
                                 'reporter' => 'reporter' } }
      let(:attrs) { { 'fields' => not_equal_fields } }
      let(:permissions) { { 'modify_reporter' => { 'havePermission' => false } } }
      before do
        allow(project).to receive(:user_permissions) { { 'permissions' => permissions } }
      end
      context 'without exception' do
        before { allow(issue).to receive(:save!) { issue } }
        specify 'issue without points' do
          is_expected.to eq issue
        end

        context 'issue with points' do
          let(:fields) { { 'issuetype' => { 'name' => 'Chore' },
                           'timetracking' => 'originalEstimate',
                           'reporter' => 'reporter' } }
          it { is_expected.to eq issue }
        end
      end
      context 'with exception' do
        before { allow(issue).to receive(:save!) { fail(JIRA::HTTPError, e) } }
        it { is_expected.to eq 'error_log' }
      end
    end
  end

  describe '#issue_status_to_story_state' do
    let(:status) { instance_double('status', id: '1') }
    before { allow(issue).to receive(:status) { status } }
    subject { jira_issue.issue_status_to_story_state }
    it { is_expected.to eq 'unstarted' }
  end

  describe '#issue_type_to_story_type' do
    let(:issuetype) { instance_double('issuetype', id: '1') }
    before { allow(issue).to receive(:issuetype) { issuetype } }
    subject { jira_issue.issue_type_to_story_type }
    it { is_expected.to eq 'bug' }
  end

  describe '#update_status!' do
    subject { jira_issue.update_status!(story) }
    let(:response) { double 'responce' }
    let(:transitions) { { 'transitions' => [{ 'name' => 'bug', 'id' => 3 }] } }
    before { allow(response).to receive(:body) { transitions.to_json } }
    before do
      allow(client).to receive(:get) { response }
      allow(client).to receive(:post) { 'send_post' }
    end
    before { allow(issue).to receive(:id) { 3 } }
    before { allow(story).to receive(:story_status_to_issue_status) { 'bug' } }

    context 'when issue is subtask' do
      let(:fields) { { 'issuetype' => { 'name' => 'Sub-task' },
                       'timetracking' => 'originalEstimate',
                       'reporter' => 'reporter' } }
      it { is_expected.to eq false }
    end

    context 'when can change status and non subtask' do
      let(:fields) { { 'issuetype' => { 'name' => 'Bug' },
                       'timetracking' => 'originalEstimate',
                       'reporter' => 'reporter' } }
      it { is_expected.to eq 'send_post' }

      specify 'post return JIRA::HTTPerror' do
        allow(allow(client).to receive(:post) { fail(JIRA::HTTPError, e) })
        is_expected.to eq 'error_log'
      end
    end
  end

  describe '#create_notes!' do
    subject { jira_issue.create_notes!(story) }
    let(:note) { double 'note' }
    before { allow(note).to receive(:text) { 'text' } }
    before do
      allow(story).to receive(:notes) { [note] }
      allow(story).to receive(:client) { story }
      allow(story).to receive(:project) { pivotal_project }
      allow(story).to receive(:url) { 'url' }
    end
    context 'when notes not exist' do
      before { allow(story).to receive(:notes) {} }
      it { is_expected.to be false }
    end

    context 'when notes is exist' do
      let(:pivotal_project) { double 'pivotal_project' }
      let(:author) { double 'author' }
      before { allow(author).to receive(:name) { 'author' } }
      before do
        allow(comment).to receive(:build) { comment }
        allow(comment).to receive(:save).and_return('save_comment')
      end
      before { allow(issue).to receive(:comments) { comment } }
      before do
        allow(pivotal_project).to receive(:memberships) { pivotal_project }
        allow(pivotal_project).to receive(:map) { pivotal_project }
        allow(pivotal_project).to receive(:find) { author }
      end
      it { is_expected.to eq [note] }

      specify 'when exception exist' do
        allow(pivotal_project).to receive(:find) { fail(JIRA::HTTPError, e) }
        is_expected.to eq [note]
      end
    end
  end
end