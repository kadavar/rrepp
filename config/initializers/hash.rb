class Hash
  def compact_keys
    delete_if { |k, v| k.nil? }
  end
end
