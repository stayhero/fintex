defmodule FinTex.Parser.Serializer do
  @moduledoc false

  alias FinTex.Model.Dialog
  alias FinTex.Command.AbstractCommand
  alias FinTex.Parser.Lexer
  alias FinTex.Parser.TypeConverter
  alias FinTex.Segment.HNVSD
  alias FinTex.Segment.HNVSK

  use AbstractCommand
  use Timex


  def serialize(segments, d = %Dialog{}) do
    segments = segments
    |> escape
    |> Stream.with_index
    |> Stream.map(fn {[[h, _ | t] | tail], index} -> [[h |> to_string |> String.upcase, index + 1 | t] | tail] end)

    segments = if d |> Dialog.anonymous? do
      segments # anonymous access is not encrypted
    else
      segments |> encrypt(d)
    end

    string = segments |> Lexer.join_segments
    size = string
    |> byte_size
    |> Kernel.-(byte_size("$SIZE"))
    |> Kernel.+(12)
    |> Integer.to_string
    |> String.rjust(12, ?0)

    ~r/\$SIZE/
    |> Regex.replace(string, "#{size}")
  end


  def deserialize(raw) when is_binary(raw) do
    s = Lexer.segment_end
    decryption = Regex.compile!("(HNHBK.*)#{s}(HNVSK.*)#{s}(HNVSD.*)#{s}(HNHBS.*)#{s}", "s")
    plain      = Regex.compile!("(HNHBK.*)#{s}(.*)#{s}(HNHBS.*)#{s}", "s")

    segments = Regex.run(decryption, raw, capture: :all_but_first)

    case segments do
      [_|_] ->
        message_header   = segments |> Enum.at(0) |> split
        signature_header = segments |> Enum.at(1) |> split
        footer           = segments |> Enum.at(3) |> split
        segments         = segments |> Enum.at(2) |> split
        Stream.concat [message_header, signature_header, segments, footer]
      nil ->
        segments = Regex.run(plain, raw, capture: :all_but_first)

        case segments do
          [_|_] ->
            message_header  = segments |> Enum.at(0) |> split
            footer          = segments |> Enum.at(2) |> split
            segments        = segments |> Enum.at(1) |> split
            Stream.concat [message_header, segments, footer]
          nil ->
            raw |> split |> List.wrap
        end
    end
  end


  def escape(segments) do
    segments |> Enum.map(fn s ->
      cond do
        is_list(s) -> escape(s)
        is_binary(s) && !Lexer.escaped_binary?(s) -> s |> to_string |> Lexer.escape
        :else -> s |> to_string
      end
    end)
  end


  defp encrypt(segments, d = %Dialog{}) do
    [hnhbk | tail] = segments |> Enum.to_list
    [
      hnhbk,
      %HNVSK{}                              |> create(d) |> TypeConverter.type_to_string,
      %HNVSD{tail: tail |> Stream.drop(-1)} |> create(d) |> TypeConverter.type_to_string,
      tail |> Enum.at(-1)
    ]
  end


  defp split(raw = "HNVSD" <> _) do
    "^HNVSD:.+@\\d+@(.*)#{Lexer.segment_end}$"
    |> Regex.compile!("sU")
    |> Regex.replace(raw, "\\1")
    |> split
  end


  defp split(raw) do
    raw |> Lexer.split
  end
end
