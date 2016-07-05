defmodule ExUtils.Test.Helper do
  defmacro __using__(repo: repo) do
    quote do
      ExUnit.start

      Ecto.Adapters.SQL.Sandbox.mode(unquote(repo), :manual)
    end
  end
end