class JiraToPivotal::DifferenceChecker < JiraToPivotal::Base
  def initialize(project)
    @user_permissions = JiraToPivotal::Jira::UserPermissions.new(project)
  end

  def main_attrs_difference?(story_attrs, jira_issue)
    main_attrs_diff(story_attrs, jira_issue)
  end

  def status_difference?(jira_issue, story)
    status_diff(jira_issue, story)
  end

  private

  def main_attrs_diff(story_attrs, jira_issue)
    story_attrs['fields']['summary'] != jira_issue.issue.fields['summary'] ||
    story_attrs['fields']['description'] != jira_issue.issue.fields['description'].to_s ||
    check_task_type_diff(story_attrs, jira_issue) ||
    check_reporter_diff(story_attrs, jira_issue.issue) ||
    check_asignee_diff(story_attrs, jira_issue.issue)
  end

  def check_task_type_diff(story_attrs, jira_issue)
    if jira_issue.subtask?
      false
    else
      story_attrs['fields']['issuetype']['id'] != jira_issue.issue.fields['issuetype']['id']
    end
  end

  def check_reporter_diff(story_attrs, jira_issue)
    if @user_permissions.modify_reporter?
      if story_attrs['fields']['reporter'].present? && jira_issue.fields['reporter'].present?
        story_attrs['fields']['reporter']['name'] != jira_issue.fields['reporter']['name']
      elsif story_attrs['fields']['reporter'].present? && !jira_issue.fields['reporter'].present?
        true
      else
        false
      end
    else
      false
    end
  end

  def check_asignee_diff(story_attrs, jira_issue)
    if @user_permissions.assign_issue?
      if story_attrs['fields']['assignee'].present? && jira_issue.fields['assignee'].present?
        story_attrs['fields']['assignee']['name'] != jira_issue.fields['assignee']['name']
      elsif story_attrs['fields']['assignee'].present? && !jira_issue.fields['assignee'].present?
        true
      else
        false
      end
    else
      false
    end
  end

  def status_diff(jira_issue, story)
    story.current_story_status_to_issue_status != jira_issue.fields['status']['name']
  end
end
