FactoryGirl.define do
  factory :config, class: Project::Config do
    tracker_project_id '123321'
    name 'test_config'
    retry_count '5'
    jira_login 'admin'
    jira_host 'jira.example.com'
    jira_uri_scheme 'https'
    jira_project 'TEST'
    jira_port '80'
    jira_filter '10000'
    script_first_start '5'
    script_repeat_time '5'
  end
end
