defmodule ExUtils.SimpleTimedJob do
  @moduledoc """
  Sets up a module to be a GenServer that will run a function then sleep for the specified time.
  This is an overly simplistic timed job process but it suits our immediate needs and removes
  a dependency on Quantum which is open source project that is running behind.
  """

  defmacro __using__({wait, function}) do
    quote do
      use GenServer

      require Logger

      def start_link do
        value = GenServer.start_link __MODULE__, unquote(function), name: __MODULE__
        spawn fn -> Sample.execute end
        value
      end

      def handle_call(:run, _from, state) do
        try do
          state.()
        rescue
          error -> Logger.error error
        end

        {:reply, nil, state}
      end

      def execute do
        Process.sleep unquote(wait)
        GenServer.call __MODULE__, :run
        execute
      end
    end
  end
end