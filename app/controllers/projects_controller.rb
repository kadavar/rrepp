class ProjectsController < ApplicationController
  before_filter :find_project, only: [:start, :stop, :force_sync]

  def index
    @projects = Project.all
  end

  def start
  end

  def stop
    Process.kill('SIGTERM', @project.pid)

    redirect_to projects_path
  end

  def synchronize
    if ProjectsHandler.perform
      flash[:success] = 'Projects was successfully synchronized'
    else
      flash[:error] = 'Synchronization failed. Contact to administator'
    end

    redirect_to projects_path
  end

  def force_sync
    start_worker @project

    render nothing: true
  end

  private

  def find_project
    @project = Project.find(params[:id])
  end

  def start_worker(project)
    random_hash = SecureRandom.hex(30)
    config = project.config.attributes
    config.merge!('jira_password' => params[:jira_password],
                  'tracker_token' => params[:pivotal_token],
                  'project_name' => project.name)

    ThorHelpers::Redis.insert_config(config, random_hash)

    SyncWorker.perform_async({ 'project' => project.name }, random_hash)
  end
end
