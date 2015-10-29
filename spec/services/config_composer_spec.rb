require 'rails_helper'
describe  ConfigComposer do

  describe '#compose_project_config' do
    let!(:project) { create :project, :online, :with_config }
    subject(:compose) { ConfigComposer.new.compose_project_config(project) }

    context 'when return the right config' do
      let (:new_fields) { { "project_id" =>project.id,
                            "project_name" => project.name,
                            "jira_custom_fields" => {} ,
                            "jira_issue_types" => {} } }
      let(:attrs) { project.config.attributes }

      it { is_expected.to include(new_fields) }
      it { is_expected.to include(attrs)  }
    end
  end

end
