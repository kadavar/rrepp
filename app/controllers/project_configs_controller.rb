class ProjectConfigsController < ApplicationController
  before_filter :find_config, only: [:edit, :update, :destroy, :show]

  def index
    @configs = Project::Config.all
  end

  def new
    @config = Project::Config.new
  end

  def create
    Project::Config.create(config_params)
  end

  def update
    Project::Config.update_attributes(config_params)
  end

  def destroy
    @config.destroy
    redirect_to project_configs_path
  end

  def synchronize
    ProjectConfigsHandler.synchronize
    redirect_to project_configs_path
  end

  private

  def find_config
    @config = Project::Config.find(params[:id])
  end

  def config_params
    params[:config].permit(:tracker_project_id, :jira_login, :jira_host, :jira_host,
                           :jira_project, :jira_port, :jira_filter, :script_first_start,
                           :script_repeat_time, :project_id, :name,
                           jira_issue_types_attributes: [:id, :name, :jira_id, :config_id],
                           jira_custom_fields_attributes: [:id, :name, :config_id])
  end
end
