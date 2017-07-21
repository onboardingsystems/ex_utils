defmodule Obs.Service do
  @moduledoc """
  Standard service actions and optional routing.
  Routing must be used in order to activate the
  service plugs. Although we use the plug pattern,
  we do not use the Plug library.
  """

  defmacro __using__(_opts) do
    quote do
      use Obs.Service.Plug
    end
  end
end
