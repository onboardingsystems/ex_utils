defmodule ExUtils.Templates do
  @moduledoc """
  ```
  defmodule Sample do
    use ExUtils.Templates

    template "relative_path/specific_file.eex"
    templates "relative_path"
  end
  ```
  """

  defmacro __using__(_opts) do
    quote do
      require EEx
      import ExUtils.Templates

      def render(file_path, assigns), do: apply(__MODULE__, convert_name(file_path), [assigns])
    end
  end

  def convert_name(file_path) do
    name = file_path
      |> String.replace(".eex", "")
      |> String.replace("/", "_")
      |> String.replace(".", "_")

    name = "render_#{name}"
      |> String.to_atom
  end

  defmacro template(file_path) do
    name = convert_name file_path
    file_path = if(String.ends_with?(file_path, ".eex"), do: file_path, else: "#{file_path}.eex")

    quote do
      EEx.function_from_file :def, unquote(name), unquote(file_path), [:assigns]
    end
  end

  defmacro templates(folder_path) do
    for path <- File.ls!(folder_path) do
      path = "#{folder_path}/#{path}"

      cond do
        File.dir?(path) ->
          quote do
            templates unquote(path)
          end
        String.ends_with?(path, ".eex") ->
          quote do
            template unquote(path)
          end
        true -> nil
      end
    end
  end
end
