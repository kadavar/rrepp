($LOAD_PATH << "#{Dir.pwd}/lib/workers").uniq!
require 'sync_worker'
