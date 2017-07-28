defmodule Obs.Service do
  @moduledoc """
  Standard service actions and optional routing.
  Routing must be used in order to activate the
  service plugs. Although we use the plug pattern,
  we do not use the Plug library.
  """

  defmacro __using__(_opts) do
    quote do
      use Obs.Plug

      import Obs.Service, only: [callable: 1]
    end
  end

  defmacro callable(name) when is_list name do
    Enum.map name, fn(entry) ->
      quote do
        callable unquote(entry)
      end
    end
  end
  defmacro callable(name) when is_tuple name do
    {entry, _, _} = name

    quote do
      callable unquote(entry)
    end
  end
  defmacro callable(name) when is_atom name do
    s_name = to_string(name)

    public_name =
      if String.starts_with?(s_name, "_") do
        s_name
        |> String.replace_prefix("_", "")
        |> String.to_atom
      else
        name
      end

    quote do
      @spec unquote(public_name)(Obs.State.t) :: Obs.State.t
      def unquote(public_name)(%Obs.State{} = state) do
        case call state do
          %Obs.State{halted: true} = updated_state -> updated_state
          updated_state -> unquote(name)(updated_state)
        end
      end

      @spec unquote(public_name)(Keyword.t, Keyword.t) :: Obs.State.t
      def unquote(public_name)(params \\ [], opts \\ []) do
        params = Enum.into params, %{}
        meta = Keyword.get opts, :meta, %{}

        state = %Obs.State{
          function: unquote(name),
          params: params,
          meta: meta
        }

        unquote(public_name)(state)
      end
    end
  end
end
