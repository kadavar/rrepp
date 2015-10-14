class ProjectConfigsReader
  def load_config(path)
    data = YAML.load(ERB.new(File.read(path)).result)
  end
end
