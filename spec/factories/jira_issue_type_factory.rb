FactoryGirl.define do
  factory :jira_issue_type, class: Jira::IssueType do
    name 'bug'
    jira_id '1'
  end
end
