require 'rails_helper'

describe ConfigComposer do

  describe '#compose_project_config' do
    let!(:project) { create :project, :online ,:with_config}
    let!(:issue_type) { create :jira_issue_type }
    let!(:custom_field) { create :jira_custom_field }
    subject(:compose) { ConfigComposer.new.compose_project_config(project) }
    context 'when return the right config' do
      before do
        project.config.jira_issue_types<<issue_type
        project.config.jira_custom_fields<<custom_field
      end

      let (:new_fields) { {"project_id" => project.id,
                           "project_name" => project.name,
                           "jira_custom_fields" =>
                            { "#{custom_field.name}" => "#{custom_field.value}" },
                           "jira_issue_types" =>
                            { "#{issue_type.name}" => issue_type.jira_id } } }
      let(:attrs) { project.config.attributes }

      it { is_expected.to include(new_fields) }
      it { is_expected.to include(attrs) }
    end
  end

end
