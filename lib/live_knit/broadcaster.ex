defmodule LiveKnit.Broadcaster do
  defmacro __using__(topic) do
    quote do
      @topic unquote(topic)
      def topic(), do: unquote(topic)

      def broadcast(message) do
        Phoenix.PubSub.broadcast(LiveKnit.PubSub, @topic, message)
      end

      def subscribe() do
        Phoenix.PubSub.subscribe(LiveKnit.PubSub, @topic)
      end
    end
  end
end
