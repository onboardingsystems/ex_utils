defmodule Obs.State do
  @moduledoc """
  Defines a standardized state reference that can be passed through
  composable OBS services.
  """

  @type assigns            :: %{atom => any}

  @type t :: %__MODULE__{
    action: (t -> t),
    assigns: assigns,
    params: assigns,
    private: assigns,
    has_errors: boolean,
    errors: assigns,
    halted: boolean
  }

  defstruct action: nil,
            assigns: %{},
            params: %{},
            private: %{},
            has_errors: false,
            errors: %{},
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
  Halts the Service pipeline by preventing further plugs downstream from being
  invoked.
  """
  @spec halt(t) :: t
  def halt(%__MODULE__{} = state) do
    %{state | halted: true}
  end

  def error(%__MODULE__{errors: errors} = state, key, value) do
    %{state | errors: Map.put(errors, key, value), has_errors: true}
  end
end
