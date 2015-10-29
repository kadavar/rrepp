require 'rails_helper'
describe ConfigComposer do

  describe '#compose_project_config' do
    let!(:project) { create :project, :online }
    let(:config) { create :config, :issues_and_custom_fields }
    let!(:issue_type) { config.jira_issue_types.first }
    let!(:custom_field) { config.jira_custom_fields.first }
    subject(:compose) { ConfigComposer.new.compose_project_config(project) }
    context 'when return the right config' do
      before { project.config = config }
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
