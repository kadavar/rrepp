FactoryGirl.define do
  factory :project do
    name 'Test project'
    pid '2389'
    online false
    last_update Time.zone.now
    created_at Time.zone.now
    updated_at Time.zone.now
  end

  trait :online do
    online true
  end

  trait :with_config do
    after :create do |project|
      FactoryGirl.create :config, :issues_and_custom_fields, project: project
    end
  end
end
