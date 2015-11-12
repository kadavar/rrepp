require 'settings_loader'

class PivotalAccountsController < ApplicationController
  before_filter :client_exist?, only: [:create, :update]
  before_filter :find_account, only: [:destroy, :update, :edit]


  def create
    @account = PivotalAccount.create(tracker_token: @client.api_token, name:@client.name)
    if(@account)
      flash[:success] = 'Configs was successfully synchronized'
    end
    redirect_to pivotal_accounts_path
  end

  def index
    @accounts = PivotalAccount.all
  end

  def update
    @account.update_attributes(account_params)
    redirect_to pivotal_accounts_path
  end

  def destroy
    @account.destroy
    redirect_to pivotal_accounts_path
  end

  private

  def find_account
    @account = PivotalAccount.find(params[:id])
  end

  def client_exist?
    @client = TrackerApi::Client.new(token: params[:pivotal_account][:tracker_token]).me

  rescue TrackerApi::Error
    flash[:success] = 'Tracker API error: Invalid Pivotal Token'
    redirect_to pivotal_accounts_path
  end

  def account_params
    params[:pivotal_account].permit(:tracker_token, :name)
  end

end