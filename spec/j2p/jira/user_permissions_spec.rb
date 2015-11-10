require 'rails_helper'

describe JiraToPivotal::Jira::UserPermissions do
  let(:client) { double 'clienst' }
  let(:permissions) { { 'permissions' =>
                          { 'perm' => { 'havePermission' => 'true' } } } }
  describe '#create_methods' do
    let(:user_permis) { JiraToPivotal::Jira::UserPermissions.new(client) }
    before do
      allow(client).to receive(:user_permissions).and_return(permissions)
    end
    subject { user_permis.perm? }

    specify 'define new method perm?' do
      is_expected.to eq 'true'
    end
  end
end
