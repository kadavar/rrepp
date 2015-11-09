require 'rails_helper'
include AuthHelper

describe ProjectsController do
  let!(:project) { create :project, :online, :with_config }
  let(:params) { { id: project.id } }
  before(:each) { http_login }

  describe '#force_sync' do
    specify 'it invokes sync_worker' do
      expect(SyncWorker).to receive(:perform_async) do |project_id|
        expect(project_id).to be project.id
      end

      get :sync_project, params
    end
  end
end
