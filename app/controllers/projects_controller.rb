class ProjectsController < BaseController
  before_filter :find_project, only: [:start, :stop, :sync_project, :destroy, :update, :edit]

  def index
    @projects = Project.all
  end

  def new
    render 'edit'
  end

  def update
    @project.update_attributes(project_params)

    redirect_to projects_path
  end

  def destroy
    @project.destroy

    redirect_to projects_path
  end

  def sync_project
    SyncWorker.perform_async(@project.id)

    render nothing: true
  end

  def status
    @projects = Project.all
  end

  private

  def find_project
    @project = Project.find(params[:id])
  end

  def project_params
    params[:project].permit(:name, :tracker_project_id,
                            :jira_project, :pivotal_account_id, :jira_account_id, :active )
  end
end
