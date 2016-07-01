defmodule ExUtils.Schema do
  def validate(message, %{} = definition) do
    ExJsonSchema.Validator.validate definition, message
  end
  def validate(message, definition), do: validate message, Poison.decode!(definition)
end