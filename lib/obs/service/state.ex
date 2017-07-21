defmodule Obs.Service.State do
  @moduledoc """
  Defines a standardized state reference that can be passed through
  composable OBS services.
  """

  @type assigns            :: %{atom => any}
  @type before_respond     :: [(t -> t)]

  @type t :: %__MODULE__{
    function: (t -> t),
    before_respond: before_respond,
    assigns: assigns,
    params: assigns,
    private: assigns,
    meta: assigns,
    success: boolean,
    response: any,
    errors: any,
    halted: boolean
  }

  defstruct function: nil,
            before_respond: [],
            assigns: %{},
            params: %{},
            private: %{},
            meta: %{},
            success: false,
            response: nil,
            errors: [],
            halted: false

  @doc """
  Assigns a new **private** key and value in the state.
  This storage is meant to be used by libraries and frameworks to avoid writing
  to the user storage (the `:assigns` field). It is recommended for
  libraries/frameworks to prefix the keys with the library name.
  For example, if some plug needs to store a `:hello` key, it
  should do so as `:plug_hello`:
      iex> state.private[:plug_hello]
      nil
      iex> state = put_private(state, :plug_hello, :world)
      iex> state.private[:plug_hello]
      :world
  """
  @spec put_private(t, atom, term) :: t
  def put_private(%__MODULE__{private: private} = state, key, value) when is_atom(key) do
    %{state | private: Map.put(private, key, value)}
  end

  @doc """
  Assigns a value to a key in the state
  ## Examples
      iex> state.assigns[:hello]
      nil
      iex> state = assign(state, :hello, :world)
      iex> state.assigns[:hello]
      :world
  """
  @spec assign(t, atom, term) :: t
  def assign(%__MODULE__{assigns: assigns} = state, key, value) when is_atom(key) do
    %{state | assigns: Map.put(assigns, key, value)}
  end

  @doc """
  Assigns a value to a param in the state
  ## Examples
      iex> state.params[:hello]
      nil
      iex> state = put_param(state, :hello, :world)
      iex> state.params[:hello]
      :world
  """
  @spec put_param(t, atom, term) :: t
  def put_param(%__MODULE__{params: params} = state, key, value) when is_atom(key) do
    %{state | params: Map.put(params, key, value)}
  end

  @doc """
  Assigns a value to a meta in the state
  ## Examples
      iex> state.meta[:hello]
      nil
      iex> state = put_meta(state, :hello, :world)
      iex> state.meta[:hello]
      :world
  """
  @spec put_meta(t, atom, term) :: t
  def put_meta(%__MODULE__{meta: meta} = state, key, value) when is_atom(key) do
    %{state | meta: Map.put(meta, key, value)}
  end

  @doc """
  Halts the Service pipeline by preventing further plugs downstream from being
  invoked.
  """
  @spec halt(t) :: t
  def halt(%__MODULE__{} = state) do
    %{state | halted: true}
  end

  @spec failed(t) :: t
  def failed(%__MODULE__{} = state) do
    %{state | success: false}
  end

  @spec successful(t) :: t
  def successful(%__MODULE__{} = state) do
    %{state | success: true}
  end

  @spec respond(t, any, Keyword.t) :: t
  def respond(%__MODULE__{} = state, response, opts \\ []) do
    success = Keyword.get opts, :success, true
    halt = Keyword.get opts, :halt, false

    state =
      state
      |> Map.put(:success, success)
      |> Map.put(:response, response)
      |> run_before_respond

    if halt do
      halt state
    else
      state
    end
  end

  def error(%__MODULE__{} = state, response, opts \\ []) do
    halt = Keyword.get opts, :halt, true
    opts = Keyword.put opts, :halt, halt
    opts = Keyword.put opts, :success, false

    respond state, response, opts
  end

  @doc """
  Registers a callback to be invoked before the response is sent.
  Callbacks are invoked in the reverse order they are defined (callbacks
  defined first are invoked last).
  """
  @spec register_before_respond(t, (t -> t)) :: t
  def register_before_respond(%__MODULE__{before_respond: before_respond} = state, callback) when is_function(callback, 1) do
    %{state | before_respond: [callback | before_respond]}
  end

  defp run_before_respond(%__MODULE__{before_respond: before_respond} = state) do
    Enum.reduce before_respond, state, &(&1.(&2))
  end
end
