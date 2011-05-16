module Views
  module NotificationMailer
    class NotificationPresenter
      include HeadlineGeneration

      attr_reader :user, :period, :item, :membership_presenters
      attr_accessor :new_election_count, :new_candidate_count, :new_comment_count

      def initialize(user, period, item=nil)
        @user, @period, @item = user, period, item
        if period == "immediately"
          build_immediate_notification
        else
          build_periodic_notification
        end
        gather_counts
      end

      def build_immediate_notification
        membership = item.organization.memberships.find(:user => user)
        @membership_presenters = [MembershipPresenter.new(membership, period, item)]
      end

      def build_periodic_notification
        @membership_presenters = memberships_to_notify.map do |membership|
          presenter = MembershipPresenter.new(membership, period, nil)
          presenter unless presenter.empty?
        end.compact
      end

      def gather_counts
        @new_election_count = 0
        @new_candidate_count = 0
        @new_comment_count = 0

        membership_presenters.each do |presenter|
          self.new_election_count += presenter.new_election_count
          self.new_candidate_count += presenter.new_candidate_count
          self.new_comment_count += presenter.new_comment_count
        end
      end

      def memberships_to_notify
        user.memberships.
          join_to(Organization).
          order_by(:social).
          project(Membership).
          all.
          select {|m| m.wants_notifications?(period)}
      end

      def subject
        "#{item_counts} on Hyperarchy"
      end

      def empty?
        membership_presenters.empty?
      end

      def multiple_memberships?
        membership_presenters.length > 1
      end

      def to_s
        lines = []
        membership_presenters.each do |presenter|
          lines.push(presenter.organization.name) if multiple_memberships?
          lines.push("")
          presenter.add_lines(lines)
          lines.push("", "", "")
        end
        lines.join("\n")
      end
    end
  end
end

