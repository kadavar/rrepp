class ProjectSyncService
  def initialize(project)
    @project = project
    @config_composer = ConfigComposer.new
  end

  def synchronize(one_time=false)
    set_flag_in_redis unless one_time
    config = @config_composer.compose_project_config(@project)

    ThorHelpers::Redis.insert_config(config, random_hash)

    SyncWorker.perform_async({ 'project' => @project.name }, random_hash)
  end

  private

  def set_flag_in_redis
    Sidekiq.redis { |connection| connection.set("#{@project.name}_sync_flag", true) }
  end

  def random_hash
    @random_hash ||= SecureRandom.hex(30)
  end
end
