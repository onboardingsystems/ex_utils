defmodule ExUtils.Test.Dataizer do
  use GenServer

  @moduledoc """
  Because eveything osunds cooler with "izer" appended to the end of it.
  """

  def start(repo) do
    GenServer.start_link(__MODULE__, %{repo: repo, registry: %{}}, name: __MODULE__)
  end

  def stop do
    pid = Process.whereis __MODULE__
    Process.exit pid, :normal
  end

  def handle_call({:insert, module, function, override}, _from, state) do
    repo = state.repo

    record = apply(module, function, [])
    record = insert_record repo, record, override

    {:reply, record, state}
  end
  def handle_call({:insert, %{} = record, override}, _from, state) do
    repo = state.repo
    record = insert_record repo, record, override

    {:reply, record, state}
  end
  def handle_call({:insert, provider_function, override}, _from, state) when is_function(provider_function) do
    repo = state.repo

    record = provider_function.()
    record = insert_record repo, record, override

    {:reply, record, state}
  end

  defp insert_record(repo, record, override) do
    record = if override do
      Map.merge record, Enum.into(override, %{})
    else
      record
    end

    repo.insert! record
  end

  @doc """
  The first parameter is the means by which the insert method will get the record.

  Passing the Ecto Schema map directly as the first parameter:

  ```elixir
    insert %MyRecord{field: "value", other: nil}, other: "overriden_value" 
  ```

  Passing a Module and Function name:

  ```elixir
    insert {MyApp.MyModule, :function_call}, other: "overriden_value"
  ```

  Passing a direct function reference or anonymous function:

  ```elixir
    insert &MyApp.MyModule.function_call/0, other: "overriden_value"
    insert fn -> %MyRecord{field: "value"} end, other: "overriden_value"
  ```
  """
  def insert(ref, override \\ nil)
  def insert({module, function}, override) do
    GenServer.call __MODULE__, {:insert, module, function, override}
  end
  def insert(ref, override) do
    GenServer.call __MODULE__, {:insert, ref, override}
  end
end
