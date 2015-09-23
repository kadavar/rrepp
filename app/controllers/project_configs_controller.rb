class ProjectConfigsController < ApplicationController
  respond_to :js, :html
  before_filter :find_config, only: [:edit, :update, :destroy, :show]

  def index
    @configs = Project::Config.all
  end

  def new
    @config = Project::Config.new
  end

  def create
    Project::Config.create(config_params)
    respond_with(@config)
  end

  def update
    @config.update_attributes(config_params)
    respond_with(@config)
  end

  def destroy
    @config.destroy
    respond_with(@config)
  end

  def synchronize
    if ProjectConfigsHandler.instance.synchronize
      flash[:success] = 'Configs was successfully synchronized'
    else
      flash[:error] = 'Synchronization failed. Contact to administator'
    end

    redirect_to project_configs_path
  end

  private

  def find_config
    @config = Project::Config.find(params[:id])
  end

  def config_params
    params[:project_config].permit(:tracker_project_id, :jira_login, :jira_host, :jira_uri_scheme,
                                   :jira_project, :jira_port, :jira_filter, :script_first_start,
                                   :script_repeat_time, :project_id, :name, :retry_count,
                                   jira_issue_types_attributes: [:id, :name, :jira_id, :config_id],
                                   jira_custom_fields_attributes: [:id, :name, :config_id])
  end
end
