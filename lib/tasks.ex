defmodule Tasks do
  defmacro deftask(name, do: block) do
    quote do
      deftask unquote(name), [] do
        unquote block
      end
    end
  end

  defmacro deftask(name, parameters, do: block) do
    if is_list(parameters) do
      quote do
        deftask unquote(name), unquote(parameters), %{} do
          unquote block
        end
      end
    else
      quote do
        deftask unquote(name), [], unquote(parameters) do
          unquote block
        end
      end
    end
  end

  defmacro deftask(name, parameters, matching, do: block) do
    function = quote do
      def unquote(name)(context, unquote(parameters)) do
        unless context[:task_error] do
          unquote(matching) = context

          result = if(true, do: unquote(block))

          if result do
            try do
              Map.merge context, result
            rescue
              _ -> throw "#{__MODULE__}.#{unquote(name)} returned #{result}. A map value is the expected return type from a task function."
            end
          else
            context
          end
        else
          context
        end
      end
    end

    # Flatten out function parameters so it is not matching an array in the function parameters
    internal_name = elem(Enum.at(elem(function, 2), 0), 0)
    internal_context = elem(Enum.at(elem(function, 2), 0), 1)
    properties = elem(Enum.at(elem(function, 2), 0), 2)
    properties = [Enum.at(properties, 0) | for(param <- Enum.at(properties, 1), do: param)]
    body = Enum.at(elem(function, 2), 1)

    {:def, [context: Tasks, import: Kernel], [{internal_name, internal_context, properties}, body]}
  end

  defmacro defptask(name, do: block) do
    quote do
      defptask unquote(name), [] do
        unquote block
      end
    end
  end

  defmacro defptask(name, parameters, do: block) do
    if is_list(parameters) do
      quote do
        defptask unquote(name), unquote(parameters), %{} do
          unquote block
        end
      end
    else
      quote do
        defptask unquote(name), [], unquote(parameters) do
          unquote block
        end
      end
    end
  end

  defmacro defptask(name, parameters, matching, do: block) do
    function = quote do
      defp unquote(name)(context, unquote(parameters)) do
        unless context[:task_error] do
          unquote(matching) = context

          result = if(true, do: unquote(block))

          if result do
            try do
              Map.merge context, result
            rescue
              _ -> throw "#{__MODULE__}.#{unquote(name)} returned #{result}. A map value is the expected return type from a task function."
            end
          else
            context
          end
        else
          context
        end
      end
    end

    # Flatten out function parameters so it is not matching an array in the function parameters
    internal_name = elem(Enum.at(elem(function, 2), 0), 0)
    internal_context = elem(Enum.at(elem(function, 2), 0), 1)
    properties = elem(Enum.at(elem(function, 2), 0), 2)
    properties = [Enum.at(properties, 0) | for(param <- Enum.at(properties, 1), do: param)]
    body = Enum.at(elem(function, 2), 1)

    {:def, [context: Tasks, import: Kernel], [{internal_name, internal_context, properties}, body]}
  end

  def task_error(error) do
    %{task_error: error}
  end

  def task_error(code, message) do
    %{task_error: %{message: message, code: code}}
  end
end
