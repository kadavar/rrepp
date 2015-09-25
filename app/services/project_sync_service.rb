class ProjectSyncService
  def initialize(project, params)
    @project = project
    @params = params
  end

  def synchronize(one_time=false)
    binding.pry
    set_flag_in_redis unless one_time

    ThorHelpers::Redis.insert_config(config_with_credentials, random_hash)

    SyncWorker.perform_async({ 'project' => @project.name }, random_hash)
  end

  private

  def set_flag_in_redis
    Sidekiq.redis { |connection| connection.set("#{@project.name}_sync_flag", true) }
  end

  def random_hash
    @random_hash ||= SecureRandom.hex(30)
  end

  def config_with_credentials
    config = @project.config.attributes
    config.merge!('jira_password' => @params[:jira_password],
                  'tracker_token' => @params[:pivotal_token],
                  'project_name' => @project.name,
                  'log_file_name' => create_log_file)
    config
  end

  def create_log_file
    file_name = "#{@project.name.underscore.gsub(' ', '_')}.log"
    file = open("log/#{file_name}", File::WRONLY | File::APPEND | File::CREAT)

    file_name
  end
end
