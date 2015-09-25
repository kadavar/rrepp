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
    binding.pry
    ProjectSyncService.new(@project, params[:project]).synchronize(true)

    render nothing: true
  end

  private

  def find_project
    @project = Project.find(params[:id])
  end
end
