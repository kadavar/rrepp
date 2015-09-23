class PathHandler
  require 'find'

  def list_of_config_names
    Find.find(Rails.root.join(default_config_path)).
      select { |p| /.*\.yml$/ =~ p }.map { |path| path.split('/').last.gsub('.yml', '') }
  end

  def default_config_path
    'config/integrations'
  end

  def config_path(name)
    Rails.root.join "#{default_config_path}/#{name}.yml"
  end
end
