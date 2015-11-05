require 'rails_helper'
describe ThorHelpers::Redis do
  let(:redis) { ThorHelpers::Redis }
  describe '#insert_config' do
    let(:config) { { 'params' => 'par' } }
    let(:hash) { SecureRandom.hex(30) }
    let(:insert_config) { Sidekiq.redis { |connection| connection.get(hash) } }
    subject { redis.insert_config(config, hash) }

    context 'insert config to Redis' do
      it { is_expected.to eq 'OK' }
    end

    specify 'get config from Redis' do
      redis.insert_config(config, hash)
      expect(insert_config).not_to eq nil
    end
  end

  describe '#update project' do
    let(:project_name) { 'project_name' }
    let(:config_path) { 'path ' }
    let(:parsed_proj) {
      { project_name => { pid: 12723,
                          last_update: Time.now.utc,
                          config_path: config_path } } }

    subject { redis.update_project(project_name, config_path) }

    context 'update projects ' do
      before do
        allow(ThorHelpers::Redis).to receive(:parsed_projets) { parsed_proj }
      end
      it { is_expected.to eq 'OK' }
    end
    context 'when parsed_projects is not present ' do
      before do
        allow(ThorHelpers::Redis).to receive(:parsed_projets) { nil }
      end
      it { is_expected.to eq 'OK' }
    end
  end

  describe '#last_update' do
    let(:project_name) { 'project_name' }
    subject { redis.last_update(project_name, 'TIME') }
    context 'when parsed_projects is not present' do
      it { is_expected.to eq 'OK' }
    end
    context 'when parsed_projects is not present' do
      before do
        Sidekiq.redis { |connection| connection.del('projects') }
      end
      it { is_expected.to be false }
    end
  end
end