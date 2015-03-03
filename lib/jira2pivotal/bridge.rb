module Jira2Pivotal
  class Bridge < Base

    def initialize(config)
      @config = Config.new(config)
    end

    def jira
      @jira ||= Jira2Pivotal::Jira::Project.new(@config)
    end

    def pivotal
      @pivotal ||= Jira2Pivotal::Pivotal::Project.new(@config)
    end

    def sync!
        connect_jira_to_pivotal!
        # Right now flow jira -> pivotal is disabled
        # from_jira_to_pivotal!
      begin
        from_pivotal_to_jira!
      rescue Exception => e
        Airbrake.notify_or_ignore(
          e,
          cgi_data: ENV.to_hash
        )
        raise
      end
    end

    def connect_jira_to_pivotal!
      stories = pivotal.unsynchronized_stories[:to_create]
      issues = jira.unsynchronized_issues[:to_update]

      pivotal_jira_connection(issues, stories)
      puts "\nSuccessfully synchronized".green
    end

    def from_pivotal_to_jira!
      # Make connection with Jira

      # Get all stories for the project from Pivotal Tracker
      puts "\nGetting all stories from #{@config['tracker_project_id']} Pivotal project"
      puts "Before update".light_blue
      puts "\nNeeds to create: #{pivotal.unsynchronized_stories[:to_create].count}".blue
      puts "Needs to update: #{pivotal.unsynchronized_stories[:to_update].count}".blue
      puts "\nStart uploading to Jira"

      begin
        update_counter = jira.update_tasks!(pivotal.unsynchronized_stories[:to_update])

        # After update issues and stories grep pivotal stories again
        # because some of them might be updated
        stories = pivotal.unsynchronized_stories

        puts "\nAfter update".light_blue
        puts "\nNeeds to create: #{stories[:to_create].count}".blue

        import_counter = jira.create_sub_task_for_invosed_issues!(stories[:to_create])
        import_counter += jira.create_tasks!(stories[:to_create])
      rescue => e
        @config[:logger].error e.message
        @config[:logger].error e.backtrace.inspect
      end

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

    def pivotal_jira_connection(issues, stories)
      mapped_issues = map_issues_by_pivotal_url(issues).reduce Hash.new, :merge

      stories_to_update(mapped_issues, stories).each do |key, value|
        issue = issues.find  { |issue| issue.issue.key == key }
        story = stories.find { |story| story.story.url == value }

        story.assign_to_jira_issue(issue.issue.key, jira.url)
      end
    end

    def stories_to_update(mapped_issues, stories)
      result = Hash.new
      stories.each do |story|
        next if mapped_issues[story.story.url].nil?

        result[mapped_issues[story.story.url]] = story.story.url if story.jira_issue_id != mapped_issues[story.story.url]
      end

      result.each { |pair| @config[:logger].info "Create connection #{pair}" } unless result.empty?

      puts "\nPivotal stories need update: #{result.count}".blue

      result
    end

    def map_issues_by_pivotal_url(issues)
      pivotal_url_id = options[:custom_fields].key(@config['jira_custom_fields']['pivotal_url'])
      issues.map { |issue| { issue.issue.send(pivotal_url_id) => issue.issue.key } }
    end
  end
end
