defmodule Fluxter.Packet do
  @moduledoc false

  def build(prefix, name, tags, fields) do
    keys = encode_key(name)
    tags = encode_tags(tags)
    fields = encode_fields(fields)

    "#{prefix}#{keys}#{tags} #{fields}"
  end

  defp encode_tags(tags) do
    for {k, v} <- tags, reduce: "" do
      acc ->
        acc <> "," <> encode_key(k) <> "=" <> encode_key(v)
    end
  end

  defp encode_fields(fields) do
    Enum.map_join(fields, ",", fn {key, val} ->
      [encode_key(key), ?=, encode_value(val)]
    end)
  end

  defp encode_key(val) do
    to_string(val) |> escape(' ,')
  end

  defp encode_value(val) do
    cond do
      is_float(val) ->
        Float.to_string(val)

      is_integer(val) ->
        [Integer.to_string(val), ?i]

      is_boolean(val) ->
        Atom.to_string(val)

      is_binary(val) ->
        [?\", escape(val, '"'), ?\"]
    end
  end

  defp escape(val, reserved) do
    for <<char <- val>>, into: "" do
      if char in reserved, do: <<?\\, char>>, else: <<char>>
    end
  end
end
