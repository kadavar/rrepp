class JiraToPivotal::Jira::OwnershipHandler < JiraToPivotal::Jira::Base
  def initialize(jira, pivotal)
    @jira    = jira
    @pivotal = pivotal
  end

  def reporter_and_asignee_attrs(story)
    result = Hash.new
    if story.story.owned_by.present? && user_jira_name(story.story.owned_by)
      result.merge!(reporter(story.story.owned_by))
            .merge!(assignee(story.story.owned_by))
    end
    result
  end

  private

  def reporter(requested_by)
    { 'reporter' => { 'name' => user_jira_name(requested_by) } }
  end

  def assignee(owned_by)
    { 'assignee' => { 'name' => user_jira_name(owned_by) } }
  end

  def pivotal_assignee
   @piv_assignee ||= @pivotal.map_users_by_email.compact
  end

  def jira_assignee
    @jira_assignee ||= @jira.jira_assignable_users
  end

  def jira_assignee_by_email
    jira_assignee['email_address'].compact_keys
  end

  def jira_assignee_by_displayed_name
    jira_assignee['display_name'].compact_keys
  end

  def jira_assignee_by_email_without_domen
    jira_assignee_by_email.reduce({}){ |hash, (k, v)| hash.merge( k.match(regexp_email_without_domen)[1] => v ) }
  end

  def pivotal_assignee_by_email_without_domen
    pivotal_assignee.reduce({}){ |hash, (k, v)| hash.merge( k => v.match(regexp_email_without_domen)[1] ) }
  end

  def user_jira_name(full_name)
    name_by_full_name = jira_assignee_by_displayed_name[full_name]
    name_by_email = check_name_by_email(full_name)

    if name_by_full_name.present? && name_by_email.present?
      if name_by_full_name == name_by_email
        name_by_email
      else
        nil
      end
    elsif name_by_email.present?
      name_by_email
    elsif name_by_full_name.present?
      name_by_full_name
    else
      nil
    end
  end

  def check_name_by_email(full_name)
    pivotal_name = pivotal_assignee_by_email_without_domen[full_name]
    result = nil

    jira_assignee_by_email_without_domen.each do |key, value|
      piv_jira_match = pivotal_name =~ /#{key}/
      jira_piv_match = key =~ /#{pivotal_name}/

      result = value if piv_jira_match || jira_piv_match
    end

    result
  end

  def regexp_email_without_domen
    /^(.+)@.+$/
  end
end
