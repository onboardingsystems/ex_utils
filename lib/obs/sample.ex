defmodule Obs.Sample do
  @moduledoc """
  Sample OBS service implementation.
  """
  use Obs.Service

  action :hello when is_nil state
  action :next

  def hello(state, _opts) do
    state
    |> assign(:result, :joe)
    |> put_private(:other, 42)
    |> error(%{errors: "Something went wrong"})
  end

  def next(state, _opts) do
    IO.inspect "Ran plug 2"
    respond state, [output: :joe]
  end
end
