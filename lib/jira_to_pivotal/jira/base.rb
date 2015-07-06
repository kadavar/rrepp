module JiraToPivotal
  module Jira
    class Base < ::JiraToPivotal::Base
      def create_tasks!(_tasks)
        fail 'Not implemented'
      end

      def update_tasks!(_tasks)
        fail 'Not implemented'
      end

      def create_notes!(_task)
        fail 'Not implemented'
      end

      def select_task(_tasks_array, _related_task)
        fail 'Not implemented'
      end
    end
  end
end
