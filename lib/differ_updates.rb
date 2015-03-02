require 'differ'
require 'differ/string'

Differ::StringDiffer.module_eval do
  def diff?(old)
    Differ.diff(self, old).to_s != self
  end
end
