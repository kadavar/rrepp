class JiraToPivotal::Jira::UserPermissions < JiraToPivotal::Jira::Base
  def initialize(client)
    self.class.create_methods(client.user_permissions)
  end

  private

  # Create methods like 'create_issues?' for these permition
  # "VIEW_WORKFLOW_READONLY", "CREATE_ISSUES","VIEW_DEV_TOOLS", "BULK_CHANGE", "CREATE_ATTACHMENT", "DELETE_OWN_COMMENTS",
  # "WORK_ON_ISSUES", "PROJECT_ADMIN", "COMMENT_EDIT_ALL", "ATTACHMENT_DELETE_OWN", "WORKLOG_DELETE_OWN", "CLOSE_ISSUE",
  # "MANAGE_WATCHER_LIST", "VIEW_VOTERS_AND_WATCHERS", "ADD_COMMENTS", "COMMENT_DELETE_ALL", "CREATE_ISSUE", "DELETE_OWN_ATTACHMENTS",
  # "DELETE_ALL_ATTACHMENTS", "ASSIGN_ISSUE", "LINK_ISSUE", "EDIT_OWN_WORKLOGS", "CREATE_ATTACHMENTS", "EDIT_ALL_WORKLOGS",
  # "SCHEDULE_ISSUE", "CLOSE_ISSUES", "SET_ISSUE_SECURITY", "SCHEDULE_ISSUES", "WORKLOG_DELETE_ALL", "COMMENT_DELETE_OWN",
  # "ADMINISTER_PROJECTS", "DELETE_ALL_COMMENTS", "RESOLVE_ISSUES", "VIEW_READONLY_WORKFLOW", "ADMINISTER", "MOVE_ISSUES",
  # "TRANSITION_ISSUES", "SYSTEM_ADMIN", "DELETE_OWN_WORKLOGS", "BROWSE", "EDIT_ISSUE", "MODIFY_REPORTER", "EDIT_ISSUES",
  # "MANAGE_WATCHERS", "EDIT_OWN_COMMENTS", "ASSIGN_ISSUES", "BROWSE_PROJECTS", "VIEW_VERSION_CONTROL", "WORK_ISSUE", "USE",
  # "COMMENT_ISSUE", "WORKLOG_EDIT_ALL", "EDIT_ALL_COMMENTS", "DELETE_ISSUE", "USER_PICKER", "CREATE_SHARED_OBJECTS",
  # "ATTACHMENT_DELETE_ALL", "DELETE_ISSUES", "MANAGE_GROUP_FILTER_SUBSCRIPTIONS", "RESOLVE_ISSUE", "ASSIGNABLE_USER",
  # "TRANSITION_ISSUE", "COMMENT_EDIT_OWN", "MOVE_ISSUE", "WORKLOG_EDIT_OWN", "DELETE_ALL_WORKLOGS", "LINK_ISSUES"

  def self.create_methods(permissions)
    permissions['permissions'].each do |permission, options|
      define_method "#{permission.downcase}?" do
        options['havePermission']
      end
    end
  end
end