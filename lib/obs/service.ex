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

  defmacro callable(name) do
    name = elem(name, 0)

    public_name =
      name
      |> to_string
      |> String.replace("_", "")
      |> String.to_atom

    quote do
      def unquote(public_name)(opts \\ []) do
        params = Keyword.get opts, :params, %{}
        meta = Keyword.get opts, :meta, %{}

        state = %Obs.State{
          function: unquote(name),
          params: params,
          meta: meta
        }

        case call state do
          %Obs.State{halted: true} = updated_state -> updated_state
          updated_state -> unquote(name)(updated_state)
        end

      end
    end
  end
end
