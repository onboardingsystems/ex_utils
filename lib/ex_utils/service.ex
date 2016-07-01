defmodule ExUtils.Service do

  defmacro __using__(_opts) do
    quote do
      use GenServer
      import ExUtils.Service
      import Ecto.Query
      import ExUtils.Schema

      def start_link(state, opts \\ []) do
        GenServer.start_link(__MODULE__, state, opts)
      end

      def handle_call({action, message}, from, state) do
        response = route_call action, message, from
        {:reply, response, state}
      end

      defp route_call(action, message, from) do
        functions = __MODULE__.__info__(:functions)

        case Keyword.get(functions, action) do
          0 -> apply(__MODULE__, action, [])
          1 -> apply(__MODULE__, action, [message])
          _ -> apply(__MODULE__, action, [message, from])
        end
      end
    end
  end

  def call(module, action, message) do
    GenServer.call module, {action, message}
  end

  def call(module, action) do
    GenServer.call module, {action, nil}
  end
end