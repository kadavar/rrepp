module Jira2Pivotal
  class Config < Base

    def initialize(path, project_name=nil)

      if File.exist?(path)
        @config = YAML.load_file(path)
        project_options = @config.delete(project_name)
        @config.merge!(project_options) unless project_options.nil?

        @config
      else
        puts "Missing config file: #{path}"
        exit 1
      end
    end

    def [](key)
      @config[key]
    end

    def jira_url
      "#{@config['jira_uri_scheme']}://#{@config['jira_host']}"
    end

    def status_map
      {
        '1'     => 'unstarted',
        '3'     => 'started',
        '4'     => 'rejected',
        '10001' => 'delivered',
        '10008' => 'accepted',
        '5'     => 'delivered',
        '6'     => 'accepted',
        '400'   => 'finished',
        '401'   => 'finished'
      }
    end

    def type_map
      {
        '1'   => 'bug',
        '2'   => 'feature',
        '3'   => 'feature',
        '4'   => 'feature',
        '5'   => 'feature',
        '6'   => 'feature',
        '7'   => 'feature',
        '8'   => 'feature',
        '9'   => 'feature',
        '10'  => 'feature'
      }
    end



  end
end
