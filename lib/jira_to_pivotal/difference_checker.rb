class JiraToPivotal::DifferenceChecker < JiraToPivotal::Base
  attr_reader :config, :user_permissions

  def initialize(project, config)
    @user_permissions = JiraToPivotal::Jira::UserPermissions.new(project)
    @config = config
  end

  def main_attrs_difference?(story_attrs, j2p_issue)
    difference_between_pivotal_jira?(jira_issue: j2p_issue.issue, story_attrs: story_attrs, j2p_issue: j2p_issue)
  end

  def status_difference?(jira_issue, story)
    status?(jira_issue, story)
  end

  private

  def difference_between_pivotal_jira?(params)
    summary?(params) || description?(params) || task_type?(params) ||
    reporter?(params) || asignee?(params) || estimates?(params)
  end

  def summary?(params)
    params[:story_attrs]['fields']['summary'] != params[:jira_issue].fields['summary']
  end

  def description?(params)
    params[:story_attrs]['fields']['description'] != params[:jira_issue].fields['description'].to_s
  end

  def task_type?(params)
    return false if params[:j2p_issue].subtask?
    params[:story_attrs]['fields']['issuetype']['id'] != params[:jira_issue].fields['issuetype']['id']
  end

  def estimates?(params)
    return false if params[:j2p_issue].bug? || params[:j2p_issue].chore? || params[:j2p_issue].subtask?

    points_field_id = config[:custom_fields].key(config['jira_custom_fields']['story_points'])
    params[:story_attrs]['fields'][points_field_id] != params[:jira_issue].fields[points_field_id] || empty_estimate?(params)
  end

  def empty_estimate?(params)
    params[:jira_issue].fields['timeoriginalestimate'].nil?
  end

  def reporter?(params)
    return false unless user_permissions.modify_reporter?

    if story_reporter(params) && jira_reporter(params)
      story_reporter(params)['name'] != jira_reporter(params)['name']
    else
      story_reporter(params) && !jira_reporter(params)
    end
  end

  def asignee?(params)
    return false unless user_permissions.assign_issue?

    if story_assignee(params) && jira_assignee(params)
      story_assignee(params)['name'] != jira_assignee(params)['name']
    else
      story_assignee(params) && !jira_assignee(params)
    end
  end

  def status?(jira_issue, story)
    story.current_story_status_to_issue_status != jira_issue.fields['status']['name']
  end

  def story_reporter(params)
    params[:story_attrs]['fields']['reporter']
  end

  def story_assignee(params)
    params[:story_attrs]['fields']['assignee']
  end

  def jira_reporter(params)
    params[:jira_issue].fields['reporter']
  end

  def jira_assignee(params)
    params[:jira_issue].fields['assignee']
  end
end
