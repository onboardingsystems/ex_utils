defmodule Obs.Sample do
  @moduledoc """
  Sample OBS service implementation.
  """
  use Obs.Service

  action :hello when function in [:_normal]
  action :next

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

  # Adds a public function that wrops a private function
  # with the standard options and enforces calling the
  # action pipeline.
  callable _normal
  callable _successful
end