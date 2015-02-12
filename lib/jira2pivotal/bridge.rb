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
      from_jira_to_pivotal!
      from_pivotal_to_jira!
    end

    def from_pivotal_to_jira!
      puts "Getting all stories from #{@config['tracker_project_id']}"

      stories = pivotal.unsynchronized_stories

      puts 'Find Stories: ', stories[:to_create].count + stories[:to_update].count
      puts 'Start uploading to Jira'

      import_counter = create_jira_issues!(stories[:to_create])
      update_counter = update_jira_issues!(stories[:to_update])

      puts "Successfully imported #{import_counter} and updated #{update_counter} stories in Jira"
    end

    def create_jira_issues!(stories)
      counter = 0
      puts 'Create new issues'

      stories.each do |story|
        putc '.'

        issue, attributes = jira.build_issue story.to_jira

        issue.save!(attributes, @config)
        issue.update_status!(jira.build_api_client, story)

        story.notes.each do |note|
          begin
            comment = issue.build_comment
            if note.text.present? # pivotal add empty note for attachment
              comment.save({ 'body' => "#{note.author} added a comment in Pivotal Tracker:: \n\n #{note.text} \n View this Pivotal Tracker story: #{story.url}" })
            end
          rescue Exception => e
            nil
          end
        end

        #*********************************************************************************************************#
        #   We can't grab attachments because there is a bug in gem and it returns all attachments from project   #
        #*********************************************************************************************************#

        issue.add_marker_comment(story.url)
        story.assign_to_jira_issue(issue.issue.key, jira.url)

        counter += 1
      end

      return counter
    end

    def update_jira_issues!(stories)
      counter = 0
      puts 'Update exists issues'

      jira_issues = jira.find_issues("id in #{@pivotal.map_stories_by_jira_id(stories)}")

      stories.each do |story|
        putc '.'

        jira_issue = story.select_issue_by_jira_issue_id(jira_issues)
        issue, attributes = jira.build_issue(story.to_jira, jira_issue)

        issue.save!(attributes, @config)
        issue.update_status!(jira.build_api_client, story)

        counter += 1
      end

      return counter
    end

    def from_jira_to_pivotal!
      # Make connection with Pivotal Tracker

      # Get all issues for the project from JIRA
      puts "Getting all the issues for #{@config['jira_project']}"

      counter =  0
      issues = jira.unsynchronized_issues

      puts 'Find Issues: ', issues.count
      puts 'Start uploading to Pivotal Tracker'

      issues.each do |issue|
        putc '.'

        story = pivotal.create_story(issue.to_pivotal)

        if story.present?

          # note_text = ''
          #
          # if issue.issuetype == '6'
          #   note_text = 'This was an epic from JIRA.'
          # end
          #
          # # Don't create comment with src, we use straight integration
          # #note_text += "\n\nSubmitted through Jira\n#{@config['jira_uri_scheme']}://#{@config['jira_host']}/browse/#{issue.key}"
          #
          # story.notes.create(text: note_text) unless note_text.blank?

          # Add notes to the story
          puts 'Checking for comments'

          issue.comments.each do |comment|
            begin     #TODO wtf?
              story.add_note( author: comment.author['displayName'], text: "*Real Author: #{comment.author['displayName']}*\n\n#{comment.body}", noted_at: comment.created)
            rescue Exception => e
              story.add_note( author: comment.author['displayName'], text: "*Real Author: #{comment.author['displayName']}*\n\n#{comment.body}", noted_at: comment.created)
            end
          end

          # Add attachments to the story

          issue.attachments.each do |attachment|
            attachment.download
            story.upload_attachment(attachment.to_path)
          end

          issue.add_marker_comment(story.url)
          story.assign_to_jira_issue(issue.key, jira.url) #we should assign jira task only at the and to prevent recending comments and attaches back

          counter += 1
        end
      end

      puts "Successfully imported #{counter} issues into Pivotal Tracker"
    end
  end
end
