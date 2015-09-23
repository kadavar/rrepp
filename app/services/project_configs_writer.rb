class ProjectConfigsWriter
  def write_config(path, config_hash)
    File.open(path, 'w') { |f| f.write config_hash.to_yaml }
  end

  def update(data, rename, path, new_path)
    File.open(path, 'w') { |f| f.write data.to_yaml }

    File.rename(path, new_path) if rename
  end
end
