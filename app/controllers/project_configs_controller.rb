class ProjectConfigsController < ApplicationController
  before_filter :find_config, only: [:edit, :update, :destroy]

  def index
    @configs = Config.all
  end

  def new
  end

  def create
  end

  def edit
  end

  def update
  end

  def destroy
  end

  def parse_configs
  end

  private

  def find_config
    @config = Config.find(params[:id])
  end
end
