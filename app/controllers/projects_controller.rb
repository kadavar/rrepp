class ProjectsController < ApplicationController
  def index
    ProjectsHandler.perform

    @projects = Project.all
  end
end
