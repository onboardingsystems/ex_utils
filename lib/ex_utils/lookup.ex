defmodule ExUtils.Lookup do
  def get(presence, service_id) do
    entries = presence.list(service_id)

    if entries do
      entries
      |> Map.keys
      |> Enum.take_random(1)
      |> get_pid(entries)
    end
  end

  defp get_pid(key, entries) do
    entries[key][:metas]
    |> Enum.at(0)
    |> Map.get(:pid)
  end
end
