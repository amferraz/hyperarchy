module Monarch
  module Rack
    class RealTimeClient
      RECONNECT_INTERVAL = 5
      attr_reader :id, :connection, :hub
      attr_accessor :user

      def initialize(id, hub)
        @id, @hub = id, hub
        @current_subscriptions = {}
        @queued_messages = []
        @send_mutex = Mutex.new
        @subscribe_mutex = Mutex.new
        start_reconnect_timer
      end

      def connection=(connection)
        send_mutex.synchronize do
          @connection = connection
          if connection
            puts "Got new connection for #{id}"
            cancel_reconnect_timer
          else
            puts "Connection dropped for #{id}, dying in #{RECONNECT_INTERVAL} seconds"
            start_reconnect_timer
          end
        end
        flush_queued_messages if connection
      end

      def send(message)
        send_mutex.synchronize do
          if connection
            connection.render(message.to_json + "\n")
          else
            queued_messages.push(message)
          end
        end
      end

      def subscribe(node_or_relation)
        subscribe_mutex.synchronize do
          subscription = node_or_relation.is_a?(Model::Relations::Relation) ?
            subscribe_to_relation(node_or_relation) : subscribe_to_node(node_or_relation)
          subscription_id = Guid.new.to_s
          current_subscriptions[subscription_id] = subscription
          subscription_id
        end
      end

      def unsubscribe(subscription_id)
        subscribe_mutex.synchronize do
          subscription_bundle = current_subscriptions.delete(subscription_id)
          subscription_bundle.destroy
        end
      end

      def unsubscribe_all
        subscribe_mutex.synchronize do
          current_subscriptions.values.each do |subscription|
            subscription.destroy
          end
        end
      end

      private
      attr_reader :reconnect_timer, :queued_messages, :current_subscriptions, :send_mutex, :subscribe_mutex

      def subscribe_to_node(node)
        node.subscribe do |message|
          send(message)
        end
      end

      def subscribe_to_relation(relation)
        bundle = Util::SubscriptionBundle.new

        bundle.add(relation.on_insert do |record|
          send(["create", relation.exposed_name.to_s, record.wire_representation])
        end)

        bundle.add(relation.on_update do |record, changeset|
          send(["update", relation.exposed_name.to_s, record.id, changeset.wire_representation])
        end)

        bundle.add(relation.on_remove do |record|
          send(["destroy", relation.exposed_name.to_s, record.id])
        end)

        bundle
      end

      def flush_queued_messages
        while !queued_messages.empty?
          send(queued_messages.shift)
        end
      end

      def start_reconnect_timer
        @reconnect_timer = EM::Timer.new(RECONNECT_INTERVAL) do
          puts "Client #{id} going offline"
          went_offline
        end
      end

      def cancel_reconnect_timer
        reconnect_timer.cancel if reconnect_timer
      end

      def went_offline
        hub.remove_client(id)
        unsubscribe_all
      end
    end
  end
end