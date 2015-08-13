require 'rails_helper'

describe 'force sync', :js do
  let!(:project) { create :project, :online, :with_config }

  before { visit projects_path }

  describe 'opens modal' do
    before { click_link("id-#{project.id}", match: :first) }

    specify 'modal exists' do
      expect(page).to have_css('input[name="jira_password"]')
      expect(page).to have_css('input[name="pivotal_token"]')
    end

    describe 'modal closing on cancel' do
      before { click 'Close' }

      specify 'modal closed' do
        expect(page).not_to have_css('input[name="jira_password"]')
        expect(page).not_to have_css('input[name="pivotal_token"]')
      end
    end
  end
end
