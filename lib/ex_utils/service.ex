defmodule ExUtils.Service do

  defmacro __using__(_opts) do
    quote do
      use GenServer
      import ExUtils.Service
    end
  end
  
end