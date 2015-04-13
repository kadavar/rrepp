class JiraToPivotal::Bridge < JiraToPivotal::Base

  def initialize(hash)
    @config = JiraToPivotal::Config.new(decrypt_config(hash))
  end

  def jira
    @jira ||= JiraToPivotal::Jira::Project.new(@config)
  end

  def pivotal
    @pivotal ||= JiraToPivotal::Pivotal::Project.new(@config)
  end

  def ownership_handler
    @handler ||= JiraToPivotal::Jira::OwnershipHandler.new(jira, pivotal)
  end

  def sync!
    connect_jira_to_pivotal!
    # Right now flow jira -> pivotal is disabled
    # from_jira_to_pivotal!
    from_pivotal_to_jira!
  rescue Exception => e
    jira.logger.error_log(e)
    Airbrake.notify_or_ignore(e, parameters: @config.for_airbrake, cgi_data: ENV.to_hash)

    raise e
  end

  def connect_jira_to_pivotal!
    stories = pivotal.unsynchronized_stories[:to_create]
    issues = jira.unsynchronized_issues[:to_update]

    pivotal_jira_connection(issues, stories)
    puts "\nSuccessfully synchronized".green
  end

  def from_pivotal_to_jira!
    # Make connection with Jira
    pivotal.update_config(ownership_handler: ownership_handler)

    # Get all stories for the project from Pivotal Tracker
    puts "\nGetting all stories from #{@config['tracker_project_id']} Pivotal project"
    puts "Before update".light_blue
    puts "\nNeeds to create: #{pivotal.unsynchronized_stories[:to_create].count}".blue
    puts "Needs to update: #{pivotal.unsynchronized_stories[:to_update].count}".blue
    puts "\nStart uploading to Jira"

    update_counter = jira.update_tasks!(pivotal.unsynchronized_stories[:to_update])

    # After update issues and stories grep pivotal stories again
    # because some of them might be updated
    stories = pivotal.unsynchronized_stories

    puts "\nAfter update".light_blue
    puts "\nNeeds to create: #{stories[:to_create].count}".blue

    import_counter = jira.create_sub_task_for_invosed_issues!(stories[:to_create])
    import_counter += jira.create_tasks!(stories[:to_create])

    puts "\nSuccessfully imported #{import_counter} and updated #{update_counter} stories in Jira".green
  end

  def from_jira_to_pivotal!
    # Make connection with Pivotal Tracker

    # Get all issues for the project from JIRA
    puts "Getting all the issues for #{@config['jira_project']}"

    puts 'Needs to create: ', jira.unsynchronized_issues[:to_create].count
    # puts 'Needs to update: ', issues[:to_update].count
    puts 'Start uploading to Pivotal Tracker'

    import_counter = pivotal.create_tasks!(jira.unsynchronized_issues[:to_create], options)
    # Not finished yet
    # Need more clarification
    # update_counter = pivotal.update_tasks!(issues[:to_update])
    update_counter = 0

    puts "\nSuccessfully imported #{import_counter} and updated #{update_counter} issues into Pivotal Tracker"
  end

  def options
    {
      custom_fields: jira.issue_custom_fields
    }
  end

  private

  def decrypt_config(hash)
    crypt = ActiveSupport::MessageEncryptor.new(hash)

    encrypted_data = Sidekiq.redis {|connection| connection.get(hash) }
    decrypted_back = crypt.decrypt_and_verify(encrypted_data)

    JSON.parse(decrypted_back)
  end

  def pivotal_jira_connection(issues, stories)
    mapped_issues = map_issues_by_pivotal_url(issues).reduce Hash.new, :merge

    stories_to_update(mapped_issues, stories).each do |key, value|
      issue = issues.find  { |issue| issue.issue.key == key }
      story = stories.find { |story| story.story.url == value }

      story.assign_to_jira_issue(issue.issue.key, jira.url)

      logger.jira_logger.update_jira_pivotal_connection_log(key, value)
    end
  end

  def stories_to_update(mapped_issues, stories)
    result = Hash.new
    stories.each do |story|
      next if mapped_issues[story.story.url].nil?

      result[mapped_issues[story.story.url]] = story.story.url if story.jira_issue_id != mapped_issues[story.story.url]
    end

    puts "\nPivotal stories need update: #{result.count}".blue

    result
  end

  def map_issues_by_pivotal_url(issues)
    pivotal_url_id = options[:custom_fields].key(@config['jira_custom_fields']['pivotal_url'])
    issues.map { |issue| { issue.issue.send(pivotal_url_id) => issue.issue.key } }
  end
end
