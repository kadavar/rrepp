require 'differ'

Differ.module_eval do
  class << self
    def diff_from_original?(current, original)
      Differ.diff_by_line(current, original).to_s != original
    end
  end
end
