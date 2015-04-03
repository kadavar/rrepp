class JiraToPivotal::Jira::Project < JiraToPivotal::Jira::Base

  attr_accessor :config

  def initialize(config)
    @config = config
    @start_index = 0

    build_api_client

    @config.delete('jira_password')
    @config.merge!(custom_fields: issue_custom_fields)
  end

  def build_api_client
    @client ||= JIRA::Client.new({
         username:     config['jira_login'],
         password:     config['jira_password'],
         site:         url,
         context_path: '',
         auth_type:    :basic,
         use_ssl:      ssl?,
         # ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE
     })
  end

  def project
    retries ||= @config['script_repeat_time'].to_i
    @project ||= @client.Project.find(@config['jira_project'])
  rescue JIRA::HTTPError =>  error
    retry unless (retries -= 1).zero?

    logger.error_log(error)
    Airbrake.notify_or_ignore(
      error,
      parameters: { config: @config.for_airbrake },
      cgi_data: ENV.to_hash
      )
    raise error
  end

  def update_config(options)
    @config.merge!(options)
  end

  def ssl?
    config['jira_uri_scheme'] == 'https'
  end

  def url
    config.jira_url
  end

  def options_for_issue(issue=nil)
    { client: build_api_client, project: project, issue: issue, config: @config }
  end

  def build_issue(attributes, issue=nil)
    attributes = { 'fields' =>  { 'project' =>  { 'id' => project.id } }.merge(attributes) }

    issue = issue.present? ? issue : @client.Issue.build(attributes)
    return JiraToPivotal::Jira::Issue.new(options_for_issue(issue)), attributes
  end

  def difference_checker
    @difference_checker ||= JiraToPivotal::DifferenceChecker.new(@project)
  end

  def next_issues
    list = issues(@start_index)

    if list.present?
      @start_index += per_page

      list
    else
      []
    end
  end

  def unsynchronized_issues
    @unsynchronized_issues ||= load_unsynchronized_issues
  end

  def load_unsynchronized_issues
    unsynchronized_issues = []
    issues = next_issues

    while issues.count > 0

      puts "Issues Find: #{issues.count}"

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

        unsynchronized_issues << JiraToPivotal::Jira::Issue.new(options_for_issue(issue)) #unless already_scheduled?(issue)
      end

      issues = issues.count > per_page ? next_issues : []
    end

    # unsynchronized_issues
    split_issues_for_create_update(unsynchronized_issues)
  end

  def split_issues_for_create_update(issues)
    result = { to_create: [], to_update: [] }

    issues.each do |issue|
      if issue.issue.attrs['fields'][jira_pivotal_field].present?
        result[:to_update] << issue
      else
        result[:to_create] << issue
      end
    end
    result
  end

  def find_issues(jql, options={})
    response = JIRA::Resource::Issue.jql(@client, jql, options)
  rescue JIRA::HTTPError => e
    logger.error_log(e)
    Airbrake.notify_or_ignore(
      e,
      parameters: { jql: jql },
      cgi_data: ENV.to_hash
      )
    return []
  end

  def create_tasks!(stories)
    counter = 0
    puts "\nCreate new issues"

    stories.each do |story|
      putc '.'
      issue, attributes = build_issue story.to_jira(@config[:custom_fields])

      next unless issue.save!(attributes, @config)

      logger.jira_logger.create_issue_log(story, issue, attributes)

      issue.update_status!(story)
      issue.create_notes!(story)
      # issue.add_marker_comment(story.url)

      #*********************************************************************************************************#
      #   We can't grab attachments because there is a bug in gem and it returns all attachments from project   #
      #*********************************************************************************************************#

      story.assign_to_jira_issue(issue.issue.key, url)

      counter += 1
    end

    return counter
  end

  def update_tasks!(stories)
    counter = 0
    puts "\nUpdate exists issues"

    incorrect_jira_ids, correct_jira_ids = check_deleted_issues_in_jira(stories.map(&:jira_issue_id))

    cleaned_stories_count = remove_jira_id_from_pivotal(incorrect_jira_ids, stories)

    if correct_jira_ids.present?
      jira_issues = find_issues("id in #{map_jira_ids_for_search(correct_jira_ids)}")
      stories.each { |story| update_issue!(story, jira_issues); counter += 1 }
    end

    return counter
  end

  def create_sub_task_for_invosed_issues!(stories)
    counter = 0

    story_urls = stories.map{ |story| story.story.url }

    return counter unless story_urls.present?

    puts "\nUpdate Invoiced issues - create subtasks"

    jira_issues = find_issues("project=#{@config['jira_project']} AND 'Pivotal Tracker URL' IN #{map_jira_ids_for_search(story_urls)} AND status = Invoiced")

    jira_issues.each do |issue|
      story = stories.find { |story| story.url == issue.send(jira_pivotal_field) }

      next unless story.present?
      putc '.'

      subtask = create_sub_task!(issue, story.url)

      next unless subtask

      story.assign_to_jira_issue(subtask.key, url)

      old_issue, attrs = build_issue({}, issue)
      logger.jira_logger.invoced_issue_log(story: story, issue: subtask, old_issue: old_issue)

      stories.delete(story)
      counter += 1
    end

    counter
  end

  def update_issue!(story, jira_issues)
    putc '.'


    jira_issue = select_task(jira_issues, story)
    return if jira_issue.nil?

    issue, attributes = build_issue(story.to_jira(@config[:custom_fields]), jira_issue)

    if difference_checker.main_attrs_difference?(attributes, issue)
      logger.jira_logger.update_issue_log(story, issue, attributes)
      return false unless issue.save!(attributes, @config)
    end

    if difference_checker.status_difference?(jira_issue, story)
      return false unless issue.update_status!(story)
      logger.jira_logger.update_issue_status_log(story, issue)
    end

    true
  end

  def create_sub_task!(issue, story_url)
    attributes =
      { 'parent' => { 'id' => parent_id_for(issue) },
        'summary' => issue.fields['summary'],
        'issuetype' => {'id' => '5'},
        'description' => issue.fields['description'].to_s,
        jira_pivotal_field => issue.send(jira_pivotal_field)
      }

    sub_task, attrs = build_issue(attributes)

    return false unless sub_task.save!(attrs, @config)

    logger.jira_logger.create_sub_task_log(story_url: story_url,
                                           issue_key: sub_task.key,
                                           old_issue_key: issue.key,
                                           attrs: attributes)

    sub_task
  end

  def parent_id_for(issue)
    j2p_issue, attrs = build_issue({}, issue)
    j2p_issue.subtask? ? issue.fields['parent']['id'] : issue.id
  end

  def select_task(issues, story)
    issues.find { |issue| issue.key == story.jira_issue_id }
  end

  def issue_custom_fields
    @issue ||= project.issue_with_name_expand
    @issue.names
  end

  def jira_assignable_users
    result = Hash.new
    ['emailAddress', 'displayName' ].each do |elem|
      result.merge!(elem.underscore => project.asignable_users.map {|u| {u[elem] => u['name']} }.reduce(Hash.new, :merge))
    end
    result
  end

  private

  def map_jira_ids_for_search(jira_ids)
    "(#{jira_ids.map { |s| "'#{s}'" }.join(',')})"
  end

  def check_deleted_issues_in_jira(pivotal_jira_ids)
    jira_issues, deleted_jira_ids = find_deleted_jira_issues(pivotal_jira_ids)

    invoiced_issues_ids = jira_issues.select { |issue| issue.status.name == 'Invoiced' }.map(&:key)
    correct_jira_ids = jira_issues.map(&:key) & pivotal_jira_ids - invoiced_issues_ids

    return deleted_jira_ids, correct_jira_ids
  end

  def find_deleted_jira_issues(pivotal_jira_ids)
    jira_issues = find_issues("key in #{map_jira_ids_for_search(pivotal_jira_ids)}", max_results: 100)
    return jira_issues, [] if jira_issues.present?

    jira_issues, deleted_ids = Array.new, Array.new

    pivotal_jira_ids.each do |key|
      issue = find_issues("key = #{key}")
      issue.present? ? jira_issues += issue : deleted_ids << key
    end

    [jira_issues, deleted_ids]
  end

  def remove_jira_id_from_pivotal(jira_ids, stories)
    for_clean_stories = stories.select { |s| jira_ids.include?(s.jira_issue_id) }
    for_clean_stories.each { |story| story.assign_to_jira_issue('nil', 'nil') }

    return for_clean_stories.count
  end

  def comment_text
    'A Pivotal Tracker story has been created for this Issue'
  end

  def already_scheduled?(jira_issue)
    jira_issue.comments.each do |comment|
      return true if comment.body =~ Regexp.new(comment_text)
    end

    false
  end

  def per_page
    50
  end

  def issues(start_index)
    if config['jira_filter']
      project.issues_by_filter(config['jira_filter'], start_index)
    else
      project.issues(start_index)
    end

  end

  def jira_pivotal_field
    pivotal_url = @config['jira_custom_fields']['pivotal_url']
    @config[:custom_fields].key(pivotal_url)
  end
end
