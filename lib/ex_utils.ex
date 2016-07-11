defmodule ExUtils do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Start Phoenix Distributed Elixir PubSub
      supervisor(Phoenix.PubSub.PG2, [ExUtils.GlobalPresence.PubSub, [name: ExUtils.GlobalPresence.PubSub, pool_size: 10]]),
      # Start Phoenix Presence
      supervisor(ExUtils.GlobalPresence, []),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExUtil.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def lookup(service_id) do
    entries = ExUtils.GlobalPresence.list(service_id)

    if entries |> Map.keys |> length > 0 do
      entries
      |> Map.keys
      |> Enum.take_random(1)
      |> Enum.at(0)
      |> get_pid(entries)
    end
  end

  defp get_pid(key, entries) do
    entries[key][:metas]
    |> Enum.at(0)
    |> Map.get(:pid)
  end
end
