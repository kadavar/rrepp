require 'rails_helper'

describe 'force sync', :js do
  let!(:project) { create :project, :online, :with_config }

  before do
    visit projects_path
  end

  before do
    click_link("id-#{project.id}", match: :first)
  end
  specify 'starts sync worker' do
    expect(config).to eq {}
  end
end
