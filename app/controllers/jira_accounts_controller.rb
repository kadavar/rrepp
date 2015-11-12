class JiraAccountsController < ApplicationController
  before_filter :find_account, only: [:destroy, :update, :edit]

  def create
     @account = JiraAccount.create(account_params)
    if(@account)
      flash[:success] = 'Configs was successfully synchronized'
    end
    redirect_to jira_accounts_path
  end

  def index
    @accounts = JiraAccount.all
  end

  def update
    @account.update_attributes(account_params)
    redirect_to jira_accounts_path
  end

  def destroy
    @account.destroy
    redirect_to jira_accounts_path
  end

  private

  def find_account
    @account = JiraAccount.find(params[:id])
  end


  def account_params
    params[:jira_account].permit(:login, :password, :jira_filter)
  end

end

