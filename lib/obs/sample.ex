defmodule Obs.Sample do
  @moduledoc """
  Sample OBS service implementation.
  """
  use Obs.Service

  pre_action :hello when params[:check] == String.to_atom("joe")
  pre_action :next

  def hello(state, _opts) do
    state
    |> assign(:result, :joe)
    |> put_private(:other, 42)
    |> error(:joe)
  end

  def next(state, _opts) do
    IO.inspect "Ran plug 2"
    state
  end

  defp _normal(state) do
    respond state, :TA_DA
  end

  defp _successful(state) do
    IO.inspect "Ran successful"
    respond state, :TA_DA
  end

  @doc """
  Do something normal.
  Comment as normal since this is where the public function
  will be declared.
  """
  callable _normal
  callable [_successful]
end
