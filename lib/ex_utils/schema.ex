defmodule ExUtils.Schema do
  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import Ecto.Query, only: [from: 1, from: 2]
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
        {val1, [count: val2]} -> String.replace(val1, "%{count}", Integer.to_string(val2))
        {val1, _} -> val1
        val -> val
      end
    end
  end

  @doc """
  Converts a changeset and all child changesets to a stuctured map.
  """
  def interpret_errors(value, name \\ "root", acc \\ %{})
  def interpret_errors(%Ecto.Changeset{changes: changes, errors: errors}, name, acc) do
    error_list = for key <- Map.keys changes do
      interpret_errors changes[key], "#{name}.#{key}", acc
    end

    # Filter out children without errors.
    error_list = Enum.filter error_list, fn(entry) -> entry != %{} end

    # Flatten into single map.
    acc = Enum.reduce error_list, acc, fn(entry, sub) -> Map.merge sub, entry end

    # Process the errors for this level.
    error_output = errors_to_map errors

    # Filter out this level if no errors are present.
    if error_output == %{} do
      acc
    else
      Map.merge acc, %{name => error_output}
    end
  end
  def interpret_errors(value, name, acc) when is_list value do
    interpret_errors_from_list value, name, acc
  end
  def interpret_errors(_, _, _), do: %{}

  defp interpret_errors_from_list(value, name, acc, index \\ 0)
  defp interpret_errors_from_list([], _name, acc, _index), do: acc
  defp interpret_errors_from_list([h | t], name, acc, index) do
    error_output = interpret_errors(h, "#{name}[#{index}]", acc)
    interpret_errors_from_list(t, name, error_output, index + 1)
  end  

  @doc """
  Scan through the model structure and remove __meta__ keys from Ecto Models. Converts the struct to a generic Map.
  """
  def convert_model_to_map(model, convert_ecto \\ true)
  def convert_model_to_map(nil, _convert_ecto), do: nil
  def convert_model_to_map(%{} = model, convert_ecto) do
    keys = List.delete Map.keys(model), :__meta__
    keys = List.delete keys, :__struct__

    key_values = for key <- keys do
      convert_value key, Map.get(model, key), convert_ecto
    end

    Enum.into key_values, %{}
  end
  def convert_model_to_map(value, _convert_ecto), do: value

  defp convert_value(key, %Ecto.Association.NotLoaded{}, true), do: {key, :not_loaded}
  defp convert_value(key, %Ecto.Time{} = value, true), do: {key, value |> Ecto.Time.to_erl |> Time.from_erl!}
  defp convert_value(key, %Ecto.Date{} = value, true), do: {key, value |> Ecto.Date.to_erl |> Date.from_erl!}
  defp convert_value(key, %Ecto.DateTime{} = value, true), do: {key, value |> Ecto.DateTime.to_erl |> NaiveDateTime.from_erl!}
  defp convert_value(key, %{} = value, convert_ecto), do: {key, convert_model_to_map(value, convert_ecto)}
  defp convert_value(key, [%{} = h | t], convert_ecto) do
    first = convert_model_to_map(h, convert_ecto)

    rest = for entry <- t do
      convert_model_to_map(entry, convert_ecto)
    end

    {key, [first | rest]}
  end
  defp convert_value(key, value, _convert_ecto), do: {key, value}
  
end