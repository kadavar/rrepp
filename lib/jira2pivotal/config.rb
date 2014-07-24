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
  end
end
