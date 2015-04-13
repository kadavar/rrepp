class JiraToPivotal::DifferenceChecker < JiraToPivotal::Base
  def initialize(project)
    @user_permissions = JiraToPivotal::Jira::UserPermissions.new(project)
  end

  def main_attrs_difference?(story_attrs, jira_issue)
    @story_attrs = story_attrs
    @jira_issue = jira_issue

    main_attrs_diff
  end

  def status_difference?(jira_issue, story)
    status_diff(jira_issue, story)
  end

  private

  def main_attrs_diff
    summary_diff || description_diff || task_type_diff || reporter_diff || asignee_diff
  end

  def story_attrs
    @story_attrs
  end

  def jira_issue
    @jira_issue
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
    story_attrs['fields']['summary'] != jira_issue.issue.fields['summary']
  end

  def description_diff
    story_attrs['fields']['description'] != jira_issue.issue.fields['description'].to_s
  end

  def task_type_diff
    return false if jira_issue.subtask?
    @story_attrs['fields']['issuetype']['id'] != jira_issue.issue.fields['issuetype']['id']
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
end
