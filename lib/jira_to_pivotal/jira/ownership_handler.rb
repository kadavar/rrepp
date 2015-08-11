module JiraToPivotal
  module Jira
    class OwnershipHandler < Jira::Base
      attr_reader :jira, :pivotal, :config

      def initialize(jira, pivotal, config)
        @jira    = jira
        @pivotal = pivotal
        @config  = config
      end

      def reporter_and_asignee_attrs(story)
        result = {}

        retryable_params = {
          can_fail: false,
          with_delay: true,
          on: TrackerApi::Error,
          returns: [],
          skip_airbrake: true
        }

        owners = retryable(retryable_params) do
          story.owners
        end

        if owners.any? && user_jira_name(owners.first.name)
          result.merge!(reporter(owners.first.name)).
            merge!(assignee(owners.first.name))
        end

        result
      end

      private

      def reporter(requested_by)
        { 'reporter' => { 'name' => user_jira_name(requested_by) } }
      end

      def assignee(owned_by)
        { 'assignee' => { 'name' => user_jira_name(owned_by) } }
      end

      def pivotal_assignee
        @pivotal_assignee ||= pivotal.map_users_by_email.compact
      end

      def jira_assignee
        @jira_assignee ||= jira.jira_assignable_users
      end

      def jira_assignee_by_email
        jira_assignee['email_address'].compact_keys
      end

      def jira_assignee_by_displayed_name
        jira_assignee['display_name'].compact_keys
      end

      def jira_assignee_by_email_without_domain
        jira_assignee_by_email.reduce({}) { |hash, (k, v)| hash.merge(k.match(regexp_email_without_domain)[1] => v) }
      end

      def pivotal_assignee_by_email_without_domen
        pivotal_assignee.reduce({}) { |hash, (k, v)| hash.merge(k => v.match(regexp_email_without_domain)[1]) }
      end

      def user_jira_name(full_name)
        name_by_full_name = jira_assignee_by_displayed_name[full_name]
        name_by_email = check_name_by_email(full_name)

        if name_by_full_name.present? && name_by_email.present?
          name_by_email if name_by_full_name == name_by_email
        elsif name_by_email.present?
          name_by_email
        elsif name_by_full_name.present?
          name_by_full_name
        end
      end

      def check_name_by_email(full_name)
        pivotal_name = pivotal_assignee_by_email_without_domen[full_name] || 'Not Found'
        result = nil

        jira_assignee_by_email_without_domain.each do |key, value|
          piv_jira_match = pivotal_name =~ /#{key}/
          jira_piv_match = key =~ /#{pivotal_name}/

          result = (piv_jira_match || jira_piv_match) ? value : nil
        end

        result
      end

      def regexp_email_without_domain
        /^(.+)@.+$/
      end
    end
  end
end
