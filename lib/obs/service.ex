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
        state = %Obs.State{
          function: unquote(name)
        }

        case call state do
          %Obs.State{halted: true} -> state
          state -> unquote(name)(state)
        end

      end
    end
  end
end
