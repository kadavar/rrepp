module Jira2Pivotal
  module Jira
    class Attachment < Base

      attr_accessor :attachment, :project

      def initialize(project, attachment=nil)
        @project = project
        @attachment = attachment
      end

      def to_path
        "/tmp/#{attachment.filename}"
      end

      def download
        puts "Downloading #{attachment.filename}"
        uri = URI.parse(URI.encode("#{project.config['jira_uri_scheme']}://#{@config['jira_host']}/secure/attachment/#{attachment.id}/#{attachment.filename}"))
        Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
          req = Net::HTTP::Get.new uri.request_uri
          req.basic_auth project.config['jira_login'], project.config['jira_password']
          resp = http.request req
          open("/tmp/#{attachment.filename}", 'wb') do |file|
            file.write(resp.body)
          end
        end
      end
    end
  end
end
