defmodule ExUtils.Test.Base do


  defmacro __using__(async: async, repo: repo) do
    quote do
      use ExUnit.Case, async: unquote(async)

      import Ecto
      import Ecto.Changeset
      import Ecto.Query, only: [from: 1, from: 2]
      import ExUtils.Test.Base
      alias unquote(repo), as: Repo

      setup tags do
        :ok = Ecto.Adapters.SQL.Sandbox.checkout(unquote(repo))

        unless tags[:async] do
          Ecto.Adapters.SQL.Sandbox.mode(unquote(repo), {:shared, self()})
        end

        :ok
      end
    end
  end
end
