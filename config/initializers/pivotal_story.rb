PivotalTracker::Story.class_eval do
  def to_xml
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.story {
        # Right now we need to update only integration field(Jira)
        # Integration work on in one side Pivotal -> Jira
        xml.jira_id "#{jira_id}" if jira_id
        xml.jira_url "#{jira_url}" if jira_url
        xml.other_id "#{other_id}" if other_id
        xml.integration_id "#{integration_id}" if integration_id
      }
    end
    return builder.to_xml
  end
end
