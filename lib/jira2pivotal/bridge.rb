module Jira2Pivotal
  class Bridge < Base

    def initialize(config_file, project_name)
      DT.p config_file

      @config = Config.new(config_file, project_name)

      DT.p @config
    end

    def jira
      @jira ||= Jira2Pivotal::Jira::Project.new(@config)
    end

    def pivotal
      @pivotal ||= Jira2Pivotal::Pivotal::Project.new(@config)
    end

    def sync!
      from_jira_to_pivotal!
      # from_pivotal_to_jira!
    end

    def from_pivotal_to_jira!

      puts "Getting all stories from #{@config['tracker_project_id']}"

      counter =  0
      stories = pivotal.unsynchronized_stories

      puts 'Find Stories: ', stories.count
      puts 'Start uploading to Jira'

      stories.each do |story|
        putc '.'

        issue = jira.build_issue(story.to_jira)

        if issue.present?

          story.comments.each do |comment|
            begin
              comment = issue.comments.build
              issue.add_note( author: comment.author['displayName'], text: "*Real Author: #{comment.author['displayName']}*\n\n#{comment.body}", noted_at: comment.created)
            rescue Exception => e
              nil
            end
          end

          # Add attachments to the story
          puts 'Checking for any attachments'

          issue.attachments.each do |attachment|
            puts 'uploading attachment...'
            attachment.download
            story.upload_attachment(attachment.to_path)
            puts "Added attachment: #{attachment.to_path}"
          end


          issue.add_marker_comment(story.url)
          story.assign_to_jira_issue(issue.key, jira.url)


          counter += 1
        end

      end


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
          puts 'Checking for any attachments'

          issue.attachments.each do |attachment|
            puts 'uploading attachment...'
            attachment.download
            story.upload_attachment(attachment.to_path)
            puts "Added attachment: #{attachment.to_path}"
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
