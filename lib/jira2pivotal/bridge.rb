module Jira2Pivotal
  class Bridge < Base

    def initialize(config_file, project_name)
      @config = Config.new(config_file, project_name)
    end

    def jira
      @jira ||= Jira2Pivotal::Jira::Project.new(@config)
    end

    def pivotal
      @pivotal ||= Jira2Pivotal::Pivotal::Project.new(@config)
    end

    def sync!
      connect_jira_to_pivotal!
      # from_jira_to_pivotal!
      from_pivotal_to_jira!
    end

    def connect_jira_to_pivotal!
      stories = pivotal.unsynchronized_stories[:to_create]
      issues = jira.unsynchronized_issues(options)[:to_update]

      mapped_issues = map_issues_by_pivotal_url(issues).reduce Hash.new, :merge
      stories_to_update = stories_to_update(mapped_issues, stories)
      puts "\nPivotal stories need update: #{stories_to_update.count}".blue

      pivotal_jira_connection(stories_to_update, issues, stories)
      puts "\nSuccessfully synchronized".green
    end

    def from_pivotal_to_jira!
      # Make connection with Jira

      # Get all stories for the project from Pivotal Tracker
      puts "\nGetting all stories from #{@config['tracker_project_id']} Pivotal project\n"

      stories = pivotal.unsynchronized_stories

      puts "Needs to create: #{stories[:to_create].count}".blue
      puts "Needs to update: #{stories[:to_update].count}".blue
      puts "\nStart uploading to Jira"
      import_counter, update_counter = jira.sync!(stories, options)

      puts "\nSuccessfully imported #{import_counter} and updated #{update_counter} stories in Jira".green
    end

    def from_jira_to_pivotal!
      # Make connection with Pivotal Tracker

      # Get all issues for the project from JIRA
      puts "Getting all the issues for #{@config['jira_project']}"

      issues = jira.unsynchronized_issues(options)

      puts 'Needs to create: ', issues[:to_create].count
      # puts 'Needs to update: ', issues[:to_update].count
      puts 'Start uploading to Pivotal Tracker'

      import_counter = pivotal.create_tasks!(issues[:to_create], options)
      # Not finished yet
      # Need more clarification
      # update_counter = pivotal.update_tasks!(issues[:to_update])
      update_counter = 0

      puts "\nSuccessfully imported #{import_counter} and updated #{update_counter} issues into Pivotal Tracker"
    end

    def options
      {
        custom_fields: jira.get_custom_fields
      }
    end

    private

    def pivotal_jira_connection(stories_to_update, issues, stories)
      stories_to_update.each do |key, value|
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
      result
    end

    def map_issues_by_pivotal_url(issues)
      pivotal_url_id = options[:custom_fields].key(@config['jira_custom_fields']['pivotal_url'])
      issues.map { |issue| { issue.issue.send(pivotal_url_id) => issue.issue.key } }
    end
  end
end
