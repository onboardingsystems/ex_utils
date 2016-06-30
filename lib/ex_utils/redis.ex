defmodule ExUtils.Redis do

  @docmodule """
  Setup a pool of Redis Connections (using poolboy)
  """

  defmacro __using__([otp_app: app]) do
    quote do
      use Supervisor
      import ExUtils.Redis

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

      commands
    end
  end


  defmacro commands do
    quote do
      #
      # The pool's public API:
      #


      def command(command) do
        :poolboy.transaction(:redix_pool, &Redix.command(&1, command))
      end

      def pipeline(commands) do
        :poolboy.transaction(:redix_pool, &Redix.pipeline(&1, commands))
      end


      #
      # Convenience Functions
      #


      def get(key) do
        command ["GET", key]
      end


      def set(key, val) do
        command ["SET", key, val]
      end


      def ttl(key) do
        command ["TTL", key]
      end


      def expire(key, ttl) do
        command ["EXPIRE", key, ttl]
      end


      def del(key) do
        command ["DEL", key]
      end


      def incr(key) do
        command ["INCR", key]
      end


      def decr(key) do
        command ["DECR", key]
      end

      @doc """
      Sets a key/value pair in Redis and sets the time out. Defaults to
      604_800 (one week) if no value provided.
      """
      def set_with_timeout(key, value, ttl \\ 604_800) do
        []
        |> set(key, value)
        |> expire(key, ttl)
        |> pipeline
      end

      #
      # Pipeline Versions
      #


      def get(acc, key) do
        acc ++ [["GET", key]]
      end


      def set(acc, key, val) do
        acc ++ [["SET", key, val]]
      end


      def ttl(acc, key) do
        acc ++ [["TTL", key]]
      end


      def expire(acc, key, ttl) do
        acc ++ [["EXPIRE", key, ttl]]
      end


      def del(acc, key) do
        acc ++ [["DEL", key]]
      end


      def incr(acc, key) do
        acc ++ [["INCR", key]]
      end


      def decr(acc, key) do
        acc ++ [["DECR", key]]
      end
    end
  end

end