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

  ###
  ### CONVERT ECTO CHANGESET ERRORS TO MAP
  ###

  @doc """
  Converts a changeset errors to a single map.
  """
  @spec errors_to_map(List.t) :: Map.t
  def errors_to_map(%{} = envelope), do: errors_to_map envelope.errors
  def errors_to_map(tuples), do: append_errors(tuples, %{})

  # Append errors to list of errors.
  # Takes a prefix to append to the front of the error field name.
  # Crude errors are errors that have not been appended yet.

  # ## Examples
  #     iex> Utils.Services.ErrorService.append_errors([{:household_id, {"is missing", []}}], "prefix", %{"field" => ["is invalid"]})
  #     %{"prefix.household_id" => ["is missing"], "field" => ["is invalid"]}
  @spec append_errors(List.t, String.t, Map.t) :: Map.t
  defp append_errors([], _, errors), do: errors
  defp append_errors([error | tail], prefix, errors) do
    {field, message} = error
    message = translate_error(message)
    append_errors(tail, prefix, Map.merge(errors, %{prefix <> "." <> Atom.to_string(field) => [message]}))
  end

  # Append errors to list of errors.
  # Crude errors are errors that have not been appended yet.

  # ## Examples
  #     iex> Utils.Services.ErrorService.append_errors([{:household_id, {"is missing", []}}], %{"field" => ["is invalid"]})
  #     %{"household_id" => ["is missing"], "field" => ["is invalid"]}
  @spec append_errors(List.t, Map.t) :: Map.t
  defp append_errors([], errors), do: errors
  defp append_errors([error | tail], errors) do
    {field, message} = error
    message = translate_error(message)
    append_errors(tail, Map.merge(errors, %{Atom.to_string(field) => [message]}))
  end

  # Translate ecto changeset errors into human readable. This handles string interpolation
  
  # ## Examples
  #     iex> Utils.Services.ErrorService.translate_error({"can't be blank", []})
  #     "can't be blank"
  @spec translate_error(Tuple.t) :: String.t
  defp translate_error({msg, opts}) do
    if count = opts[:count] do
      Gettext.dngettext(ExUtils.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(ExUtils.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Converts a changeset and all child changesets to a stuctured map.
  """
  def interpret_errors(changeset, name \\ "root", acc \\ %{})
  def interpret_errors(%Ecto.Changeset{changes: changes, errors: errors}, name, acc) do
    error_list = for key <- Map.keys changes do
      interpret_errors changes[key], "#{name}.#{key}", acc
    end

    # Filter out children without errors.
    error_list = Enum.filter error_list, fn(entry) -> entry != %{} end

    # Flatten into single map.
    acc = Enum.reduce error_list, acc, fn(entry, sub) -> Map.merge sub, entry end

    # Process the errors for this level.
    append_errors errors, name, acc
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

  ###
  ### CONVERT SCHEMA AND ECTO VALUES TO ORDINARY EQUIVALENTS
  ###

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