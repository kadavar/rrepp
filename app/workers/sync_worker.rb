class SyncWorker
  include Sidekiq::Worker

  sidekiq_options failures: true, retry: false, backtrace: true, unique: true

  def perform(project_id)
    project = Project.find(project_id)
    
    if project.present?
      project.update_attributes(current_job_id: jid)
      config_composer = ConfigComposer.new
      config = config_composer.compose_project_config(project)

      bridge = JiraToPivotal::Bridge.new(config)
      bridge.sync!
    end
  end
end
