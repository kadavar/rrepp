require 'rails_helper'
include AuthHelper

describe ProjectsController do
  let!(:project) { create :project, :online, :with_config, name: 'testp' }
  let(:params) { {id: project.id} }
  before(:each) { http_login }


  describe '#force_sync' do
    specify 'it invokes sync_worker' do
      expect(SyncWorker).to receive(:perform_async) do |project_id|
        expect(project_id).to be project.id
      end

      get :sync_project, params
    end
  end

  describe '#destroy' do

    let(:params_2) { {id: project_2.id} }
    let!(:project_2) { create :project, :online, :with_config, name: 'testp2' }
    subject { response }

    specify 'have change Project count' do
      expect { delete :destroy, params }.to change(Project, :count).by(-1)
    end

    context 'redirect to project path ' do
      before { delete :destroy, params_2 }
      it { is_expected.to redirect_to projects_url }
    end
  end
end
