require 'rails_helper'

describe ProjectsController do
  let!(:project) { create :project, :online, :with_config }

  describe '#force_sync' do
    specify 'it passes right config to redis' do
      params = {
        jira_password: 'password',
        pivotal_token: 'token',
        id: project.id
      }

      expect(ThorHelpers::Redis).to receive(:insert_config) do |config, random_hash|
        expect(%w('jira_password', 'tracker_token').all? { |key| config.key? key }).to be true
      end

      get :force_sync, params
    end
  end
end
