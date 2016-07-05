defmodule ExUtils.Service do

  defmacro __using__(_opts) do
    quote do
      import ExUtils.Service
      import Ecto.Query
      import ExUtils.Schema
    end
  end

  @doc """
  Converts a changeset error keyword list to a jsonable map.
  """
  def errors_to_map(%{} = envelope), do: errors_to_map envelope.errors
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

  @doc """
  Scan through the model structure and remove __meta__ keys from Ecto Models. Converts the struct to a generic Map.
  """
  def convert_model_to_map(nil), do: nil
  def convert_model_to_map(model) do
    keys = List.delete Map.keys(model), :__meta__
    keys = List.delete keys, :__struct__

    key_values = for key <- keys do
      convert_value key, Map.get(model, key)
    end

    Enum.into key_values, %{}
  end

  defp convert_value(key, %Ecto.Association.NotLoaded{}), do: {key, :not_loaded}
  defp convert_value(key, %Ecto.Time{} = value), do: {key, value |> Ecto.Time.to_erl |> Time.from_erl!}
  defp convert_value(key, %Ecto.Date{} = value), do: {key, value |> Ecto.Date.to_erl |> Date.from_erl!}
  defp convert_value(key, %Ecto.DateTime{} = value), do: {key, value |> Ecto.DateTime.to_erl |> NaiveDateTime.from_erl!}
  defp convert_value(key, %{} = value), do: {key, convert_model_to_map(value)}
  defp convert_value(key, value), do: {key, value}


end