($LOAD_PATH << '.' << 'lib' << 'lib/workers').uniq!
require 'sync_worker'
