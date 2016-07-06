defmodule ExUtils.Service do

  defmacro __using__([repo: repo]) do
    quote do
      import ExUtils.Service
      import Ecto.Query, only: [from: 1, from: 2]
      import ExUtils.Schema

      alias unquote(repo), as: Repo
    end
  end
  defmacro __using__(_opts) do
    quote do
      import ExUtils.Service
      import Ecto.Query, only: [from: 1, from: 2]
      import ExUtils.Schema
    end
  end


end