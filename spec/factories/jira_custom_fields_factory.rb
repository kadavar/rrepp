FactoryGirl.define do
  factory :jira_custom_field, class: Jira::CustomField do
    name  'Pivotal link'
    value 'link'
  end
end
