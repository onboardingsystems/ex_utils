defmodule ExUtils.Model do

  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import Ecto.Query, only: [from: 1, from: 2]
    end
  end

  def errors_to_map(tuples) do
    Enum.reduce Keyword.keys(tuples), %{}, fn(key, acc) ->
      Map.put(acc, key, get_value(tuples, key))
    end
  end

  defp get_value(tuples, key) do
    for value <- Keyword.get_values(tuples, key) do
      case value do
        #{val1, [count: val2]} -> [val1, "value is #{val2}"]
        {val1, _} -> val1
        val -> val
      end
    end
  end
  
end