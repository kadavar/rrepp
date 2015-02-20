$LOAD_PATH << './jira4r/lib'


require 'net/http'
require 'open-uri'
require 'certified'
require 'jira'
require 'pivotal-tracker'
require 'yaml'
require 'rails_dt'
require 'pry'
require 'pry-nav'

CONFIG_FILE = 'config.yml'

if File.exist?(CONFIG_FILE)
  $config = YAML::load_file(CONFIG_FILE)
else
  puts "Missing config file: #{CONFIG_FILE}"
  exit 1
end

COMMENT_TEXT = 'A Pivotal Tracker story has been created for this Issue'

def already_scheduled?(jira_issue)
  jira_issue.comments.each do |comment|
    return true if comment.body =~ Regexp.new(COMMENT_TEXT)
  end

  false
end

# Make connection with JIRA
$jira = JIRA::Client.new({ :username => $config['jira_login'],
  :password => $config['jira_password'],
  :site =>  "#{$config['jira_uri_scheme']}://#{$config['jira_host']}",
  :context_path => '',
  :auth_type => :basic,
  use_ssl: false,
  #ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE
})

# Make connection with Pivotal Tracker
PivotalTracker::Client.token = $config['tracker_token']
$project = PivotalTracker::Project.find($config['tracker_project_id'])


# Get all issues for the project from JIRA
puts "Getting all the issues for #{$config['jira_project']}"

jira_project = $jira.Project.find($config['jira_project'])

status_map = { '1' => 'unstarted',
  '3' => 'started',
  '4' => 'rejected',
  '10001' => 'delivered',
  '10008' => 'accepted',
  '5' => 'delivered',
  '6' => 'accepted',
  '400' => 'finished',
  '401' => 'finished'
}

type_map = { '1' => 'bug',
  '2' => 'feature',
  '3' => 'feature',
  '4' => 'feature',
  '5' => 'feature',
  '6' => 'feature',
  '7' => 'feature',
  '8' => 'feature',
  '9' => 'feature',
  '10' => 'feature' }

counter =  0

issues = jira_project.issues()

DT.p 'Issues: ', issues.count

if issues.count > 0

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
    puts "Scheduling #{issue.key} with status=#{status_map[issue.status.id]}, type=#{type_map[issue.issuetype.id]}"

    story_args = {
      name:           issue.summary,
      current_state:  status_map[issue.status.id],
      requested_by:   $config['tracker_requester'],
      description:    issue.description,
      story_type:     type_map[issue.issuetype.id],
      jira_id:        issue.key,
      jira_url:       "#{$config['jira_uri_scheme']}://#{$config['jira_host']}"

    }

    if type_map[issue.issuetype.id] == 'feature'
      story_args['estimate'] = 1
    end

    if status_map[issue.status.id] == 'accepted'
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

    story = $project.stories.create(story_args)

    DT.p story

    note_text = ''

    if issue.issuetype == '6'
      note_text = 'This was an epic from JIRA.'
    end

    # Don't create comment with src, we use straight integration
    #note_text += "\n\nSubmitted through Jira\n#{$config['jira_uri_scheme']}://#{$config['jira_host']}/browse/#{issue.key}"

    story.notes.create(text: note_text) unless note_text.blank?

    # Add notes to the story
    puts 'Checking for comments'

    issue.comments.each do |comment|

      if comment.body =~ Regexp.new(COMMENT_TEXT)
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
      uri = URI.parse(URI.encode("#{$config['jira_uri_scheme']}://#{$config['jira_host']}/secure/attachment/#{attachment.id}/#{attachment.filename}"))
      Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        req = Net::HTTP::Get.new uri.request_uri
        req.basic_auth $config['jira_login'], $config['jira_password']
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
    comment.save( :body => "#{COMMENT_TEXT}: #{story.url}(iddqd)" )

    break

    counter += 1
  end

  #start_at += issues.count
  #issues = jira_project.issues
end

puts "Successfully imported #{counter} issues into Pivotal Tracker"
