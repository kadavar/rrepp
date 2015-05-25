class JiraToPivotal::DifferenceChecker < JiraToPivotal::Base
  attr_reader :story_attrs, :jira_issue, :j2p_issue,  :config

  def initialize(project, config)
    @user_permissions = JiraToPivotal::Jira::UserPermissions.new(project)
    @config = config
  end

  def main_attrs_difference?(story_attrs, j2p_issue)
    @story_attrs = story_attrs
    @jira_issue  = j2p_issue.issue
    @j2p_issue   = j2p_issue

    story_issue_diff?
  end

  def status_difference?(jira_issue, story)
    status_diff(jira_issue, story)
  end

  private

  def story_issue_diff?
    summary_diff || description_diff || task_type_diff || reporter_diff || asignee_diff || estimates_diff
  end

  def story_reporter
    @story_attrs['fields']['reporter']
  end

  def story_assignee
    @story_attrs['fields']['assignee']
  end

  def jira_reporter
    jira_issue.fields['reporter']
  end

  def jira_assignee
    jira_issue.fields['assignee']
  end

  def summary_diff
    story_attrs['fields']['summary'] != jira_issue.fields['summary']
  end

  def description_diff
    story_attrs['fields']['description'] != jira_issue.fields['description'].to_s
  end

  def task_type_diff
    return false if j2p_issue.subtask?
    story_attrs['fields']['issuetype']['id'] != jira_issue.fields['issuetype']['id']
  end

  def estimates_diff
    return false if j2p_issue.bug? || j2p_issue.chore? || j2p_issue.subtask?
    story_attrs['fields'][points_field_id] != jira_issue.fields[points_field_id] || empty_estimate?
  end

  def empty_estimate?
    jira_issue.fields['timeoriginalestimate'].nil?
  end

  def reporter_diff
    return false unless @user_permissions.modify_reporter?

    if story_reporter.present? && jira_reporter.present?
      story_reporter['name'] != jira_reporter['name']
    else
      story_reporter.present? && !jira_reporter.present?
    end
  end

  def asignee_diff
    return false unless @user_permissions.assign_issue?

    if story_assignee.present? && story_assignee.present?
      story_assignee['name'] != story_assignee['name']
    else
      story_assignee.present? && !story_assignee.present?
    end
  end

  def status_diff(jira_issue, story)
    story.current_story_status_to_issue_status != jira_issue.fields['status']['name']
  end

  def points_field_id
    points_custom_field ||= config[:custom_fields].key(config['jira_custom_fields']['pivotal_points'])
  end
end
