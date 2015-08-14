require 'rails_helper'

describe 'force sync', :js do
  let!(:project) { create :project, :online, :with_config }

  before do
    visit projects_path

    click_link("id-#{project.id}", match: :first)
  end

  describe 'opens modal' do
    specify 'modal exists' do
      expect(page).to have_css('input[name="jira_password"]')
      expect(page).to have_css('input[name="pivotal_token"]')
    end
  end

  describe 'modal closing on cancel' do
    before { click_link 'Cancel' }

    specify 'modal closed' do
      expect(page).not_to have_css('input[name="jira_password"]')
      expect(page).not_to have_css('input[name="pivotal_token"]')
    end
  end

  describe 'submit empty form' do
    before { click_link 'Force sync' }

    specify 'error message appears' do
      expect(page).to have_content('Fields can not be empty')
    end
  end

  describe 'filled form submition' do
    before do
      fill_in 'jira_password', with: 'password'
      fill_in 'pivotal_token', with: 'token'

      click_link 'Force sync'
    end

    specify 'no messge, closing' do
      expect(page).not_to have_content('Fields can not be empty')

      expect(page).not_to have_css('input[name="jira_password"]')
      expect(page).not_to have_css('input[name="pivotal_token"]')
    end
  end
end
