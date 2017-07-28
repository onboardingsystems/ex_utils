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

      import Obs.Service, only: [plug_in: 1]

      if Code.ensure_compiled? Ecto.Changeset do
        import Ecto.Changeset
      end

      def perform(%Obs.State{} = state, action) when is_atom action do
        state
        |> Map.put(:action, action)
        |> perform
      end

      def perform(%Obs.State{action: action} = state) do
        case call state do
          %Obs.State{halted: true} = updated_state -> updated_state
          updated_state -> apply(__MODULE__, action, updated_state)
        end
      end
      def perform(action, params) when is_atom action and is_list params do
        params = Enum.into params, %{}

        state = %Obs.State{
          action: action,
          params: params
        }

        perform state
      end
    end
  end

  defmacro plug_in(name) when is_list name do
    Enum.map name, fn(entry) ->
      quote do
        plug_in unquote(entry)
      end
    end
  end
  defmacro plug_in(name) when is_tuple name do
    {entry, _, _} = name

    quote do
      plugin unquote(entry)
    end
  end
  defmacro plug_in(name) when is_atom name do
    listing = Keyword.put [], name, 1

    quote do
      defoverridable unquote(listing)

      def unquote(name)(params \\ [])
      @spec unquote(name)(Obs.State.t) :: Obs.State.t
      def unquote(name)(%Obs.State{} = state) do
        state = Map.put state, :action, unquote(name)

        case call state do
          %Obs.State{halted: true} = updated_state -> updated_state
          updated_state -> super(updated_state)
        end
      end
      @spec unquote(name)(Keyword.t) :: Obs.State.t
      def unquote(name)(params) do
        params = Enum.into params, %{}

        state = %Obs.State{
          params: params,
        }

        unquote(name)(state)
      end
    end
  end
end
