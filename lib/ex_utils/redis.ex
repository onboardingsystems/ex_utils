defmodule ExUtils.Redis do

  @moduledoc """
  Setup a pool of Redis Connections (using poolboy)
  """

  defmacro __using__([opt_app: app]) do
    quote do
      @redis_connect_params host: Application.get_env(unquote(app), :redis)[:host]

      def start_link do
        Supervisor.start_link __MODULE__, []
      end

      def init(_opts) do
        pools_opts = [
          name: {:local, :redix_pool},
          worker_module: Redix,
          size: 10,
          max_overflow: 5
        ]

        children = [
          :poolboy.child_spec(:redix_pool, pools_opts, @redis_connect_params)
        ]

        supervise(children, strategy: :one_for_one, name: __MODULE__)
      end


      defp encode_term(term) do
        term
        |> :erlang.term_to_binary
      end

      defp decode_term(encoded_term) do
        encoded_term
        |> :erlang.binary_to_term
      end

      #
      # The pool's public API:
      #


      defp command(command) do
        :poolboy.transaction(:redix_pool, &Redix.command(&1, command))
      end

      defp pipeline(commands) do
        :poolboy.transaction(:redix_pool, &Redix.pipeline(&1, commands))
      end


      #
      # Convenience Functions
      #


      defp get(key), do: command ["GET", key]

      defp set(key, val), do: command ["SET", key, val]

      defp ttl(key), do: command ["TTL", key]

      defp expire(key, ttl), do: command ["EXPIRE", key, round(ttl)]

      defp del(key), do: command ["DEL", key]

      #
      # Pipeline Versions
      #

      defp set(acc, key, val), do: acc ++ [["SET", key, val]]

      defp expire(acc, key, ttl), do: acc ++ [["EXPIRE", key, ttl]]


      defp handle_response({:error, reason}), do: {:error, reason}
      defp handle_response({:ok, "OK"}), do: :ok
      defp handle_response({:ok, ["OK", _]}), do: :ok
      defp handle_response({:ok, nil}), do: {:ok, nil}
      defp handle_response({:ok, value}), do: {:ok, decode_term(value)}

      @doc """
      Sets a key/value pair in Redis and sets the time out. Defaults to
      604_800 (one week) if no value provided.

      ```elixir
        alias ObsCore.Redis

        Redis.save "session_id", user_id: 145, username: "dev"
        Redis.save "session_id", 300, user_id: 145, username: "dev"
      ```
      """
      @spec save(String.t, term, integer) :: :ok | {:error, term}
      def save(key, value, ttl \\ 604_800) do
        []
        |> set(key, encode_term(value))
        |> expire(key, ttl)
        |> pipeline
        |> handle_response
      end

      @doc """
      Updates an existing key with the new value. Can reset time to live but not required.
      When now ttl provided, the original will hold but only the value will be changed.

      ```elixir
        alias ObsCore.Redis

        # Set initial value with default 1 week time to live.
        Redis.save "key1", "Hello"

        # Update the value but the existing timeout will hold.
        Redis.update "key1", "Hello World"

        # Update the value and reset the time to live to be one minute.
        # This is the same as just using the save method again.
        Redis.update "key1", 60 "Hello World"
      ```
      """
      def update(key, value, ttl \\ nil)
      def update(key, value, nil), do: handle_response set(key, encode_term(value))
      def update(key, value, ttl), do: save key, ttl, value

      @doc """
      Extend the timeout for a key by the number of seconds provided.

      ```elixir
        alias ObsCore.Redis

        # Inital value lasts one minute.
        Redis.save "key1", 60, "Hello"

        # Change time to live to be two minutes from the time this is passed into Redis.
        Redis.reset_time_to_live "key1", 120
      ```
      """
      def reset_time_to_live(key, ttl), do: expire key, ttl

      @doc """
      Retrieve a value from Redis by Key.

      ```elixir
        alias ObsCore.Redis

        {:ok, value} = Redis.fetch "value"
      ```
      """
      def fetch(key, ttl \\ nil)
      def fetch(key, nil) do
        handle_response get(key)
      end
      def fetch(key, ttl) do
        case handle_response get(key) do
          {:error, _} = error -> error
          {:ok, _} = response ->
            expire(key, ttl)
            response
        end
      end

      @doc """
      Retrieve a value from Redis by Key. Throws an error when encountered.

      ```elixir
        alias ObsCore.Redis

        Redis.fetch! "value"
      ```
      """
      def fetch!(key, ttl \\ nil) do
        case fetch key, ttl do
          {:error, reason} -> throw reason
          {:ok, value} -> value
        end
      end

      @doc """
      Returns the seconds remaining; if time is already expired, then returns nil.
      Returning does not mean it is deleted from Redis, it just means the time to live
      has expired or the key is no longer found.
      """
      def time_left(key) do
        case ttl key do
          {:ok, seconds} when seconds > -1 -> seconds
          {:ok, _seconds} -> nil
        end
      end

      def delete(key) do
        case del key do
          {:ok, _} -> :ok
          {:error, _} = error -> error
        end
      end
    end
  end
end
