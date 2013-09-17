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

      # Make connection with Pivotal Tracker

      # Get all issues for the project from JIRA
      puts "Getting all the issues for #{@config['jira_project']}"

      counter =  0
      issues = jira.next_issues()



      DT.p 'Issues: ', issues.count

      while issues.count > 0

        issues.each do |issue|
          # Expand the issue with changelog information
          # HACK: This is just a copy of the issue.url function
          def issue.url_old
            prefix = '/'
            unless self.class.belongs_to_relationships.empty?
              prefix = self.class.belongs_to_relationships.inject(prefix) do |prefix_so_far, relationship|
                prefix_so_far + relationship.to_s + '/' + self.send("#{relationship.to_s}_id") + '/'
              end
            end

            if @attrs['self']
              @attrs['self'].sub(@client.options[:site],'')
            elsif key_value
              self.class.singular_path(client, key_value.to_s, prefix)
            else
              self.class.collection_path(client, prefix)
            end
          end

          # Override the issue url to get changelog information
          def issue.url
            self.url_old + '?expand=changelog'
          end

          issue.fetch

          if already_scheduled?(issue)
            puts "skipping #{issue.key}"
            next
          end

          # Add the issue to pivotal tracker
          puts "Scheduling #{issue.key} with status=#{@config.status_map[issue.status.id]}, type=#{@config.type_map[issue.issuetype.id]}"

          story_args = {
            name:           issue.summary,
            current_state:  @config.status_map[issue.status.id],
            requested_by:   @config['tracker_requester'],
            description:    issue.description,
            story_type:     @config.type_map[issue.issuetype.id],
            jira_id:        issue.key,
            jira_url:       "#{@config['jira_uri_scheme']}://#{@config['jira_host']}"

          }

          if @config.type_map[issue.issuetype.id] == 'feature'
            story_args['estimate'] = 1
          end

          if @config.status_map[issue.status.id] == 'accepted'
            last_accepted = nil
            issue.changelog['histories'].each do |history|
              history['items'].each do |change|

                if change['to'] == issue.status.id
                  last_accepted = history['created']
                end
              end
            end

            if last_accepted
              story_args['accepted_at'] = last_accepted
            end
          end

          story = pivotal.create_story(story_args)

          note_text = ''

          if issue.issuetype == '6'
            note_text = 'This was an epic from JIRA.'
          end

          # Don't create comment with src, we use straight integration
          #note_text += "\n\nSubmitted through Jira\n#{@config['jira_uri_scheme']}://#{@config['jira_host']}/browse/#{issue.key}"

          story.notes.create(text: note_text) unless note_text.blank?

          # Add notes to the story
          puts 'Checking for comments'

          issue.comments.each do |comment|

            if comment.body =~ Regexp.new(comment_text)
              next
            else
              begin
                story.notes.create( author: comment.author['displayName'], text: "*Real Author: #{comment.author['displayName']}*\n\n#{comment.body}", noted_at: comment.created)
              rescue Exception => e
                story.notes.create( author: comment.author['displayName'], text: "*Real Author: #{comment.author['displayName']}*\n\n#{comment.body}", noted_at: comment.created)
              end

              puts "Added comment by #{comment.author['displayName']}"
            end
          end

          # Add attachments to the story
          puts 'Checking for any attachments'

          issue.attachments.each do |attachment|
            # Download the attachment to a temporary file
            puts "Downloading #{attachment.filename}"
            uri = URI.parse(URI.encode("#{@config['jira_uri_scheme']}://#{@config['jira_host']}/secure/attachment/#{attachment.id}/#{attachment.filename}"))
            Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
              req = Net::HTTP::Get.new uri.request_uri
              req.basic_auth @config['jira_login'], @config['jira_password']
              resp = http.request req
              open("/tmp/#{attachment.filename}", 'wb') do |file|
                file.write(resp.body)
              end
            end
            attachment_resp = story.upload_attachment( "/tmp/#{attachment.filename}")
            puts "Added attachment: #{attachment.filename}"
          end

          # Add comment to the original JIRA issue
          puts 'Adding a comment to the JIRA issue'
          comment = issue.comments.build
          comment.save( :body => "#{comment_text}: #{story.url}(iddqd)" )



          counter += 1

          #break
        end


        issues = jira.next_issues()
      end

      puts "Successfully imported #{counter} issues into Pivotal Tracker"

    end


    private

    def comment_text
      'A Pivotal Tracker story has been created for this Issue'
    end

    def already_scheduled?(jira_issue)
      jira_issue.comments.each do |comment|
        return true if comment.body =~ Regexp.new(comment_text)
      end

      false
    end
  end

end
