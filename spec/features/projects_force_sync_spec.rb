require 'rails_helper'

describe 'force sync', :js do
  let!(:project) { create :project, :online, :with_config }

  before do
    create :jira_issue_type, config: project.config
    create :jira_custom_field, config: project.config

    visit projects_path

    click_link("id-#{project.id}", match: :first)
  end

  describe 'opens modal' do
    specify 'modal exists' do
      expect(page).to have_css('input[name="project[jira_password]"]')
      expect(page).to have_css('input[name="project[pivotal_token]"]')
    end
  end

  describe 'modal closing on cancel' do
    before { click_link 'Cancel' }

    specify 'modal closed' do
      expect(page).not_to have_css('input[name="project[jira_password]"]')
      expect(page).not_to have_css('input[name="project[pivotal_token]"]')
    end
  end

  describe 'click empty form' do
    before do
      page.find('#force-form').trigger(:click)
    end

    specify 'error message appears' do
      expect(page).to have_css('.list-unstyled')
    end
  end

  describe 'filled form submition' do
    before do
      fill_in 'project_jira_password', with: 'password'
      fill_in 'project_pivotal_token', with: 'token'

      click_button 'Force sync'
    end

    specify 'no messge, closing' do
      expect(page).not_to have_content('Please fill out this field.')

      expect(page).not_to have_css('input[name="project[jira_password]"]')
      expect(page).not_to have_css('input[name="project[pivotal_token]"]')
    end
  end
end
