defmodule Conmon.Util.TStamp do
  defstruct mono: 0, dt: %{}

  alias(Conmon.Util.TStamp)

  @key :ts

  @second 1000
  @minute @second * 60
  @hour @minute * 60
  @day @hour * 24
  @year @day * 365

  def new() do
    with {:ok, dt} <- DateTime.now("Etc/UTC"),
         do: %TStamp{mono: System.monotonic_time(:millisecond), dt: dt}
  end

  def stamp(m), do: Map.put(m, @key, new())

  def delta(%{ts: t = %TStamp{}}), do: {t, new()}
  def delta(raw_timestamp), do: {raw_timestamp, new()}

  # all numbers are in ms
  def timestring({%TStamp{mono: s}, %TStamp{mono: e}}) do
    # IO.puts("timestring: #{e} #{s} -> #{e - s}")
    timestring(e - s)
  end

  def timestring(d) when d >= @year, do: "#{div(d, @year)}Y, #{timestring(rem(d, @year))}"
  def timestring(d) when d >= @day, do: "#{to_s(d, @day, 3)}D, #{timestring(rem(d, @day))}"
  def timestring(d) when d >= @hour, do: "#{to_s(d, @hour)}h:#{timestring(rem(d, @hour))}"
  def timestring(d) when d >= @minute, do: "#{to_s(d, @minute)}m:#{timestring(rem(d, @minute))}"
  # def timestring(d) when d >= @second, do: "#{to_s(d, @second)}#{timestring(rem(d, @second))}"
  def timestring(d) do
    with seconds <- div(d, @second),
         ms <- rem(d, @second) do
      if ms > 0 do
        if seconds > 0 do
          "#{to_s(seconds, 1, 2)}.#{to_s(ms, 1, 3)}s"
        else
          "0.#{to_s(ms, 1, 3)}s"
        end
      else
        "#{to_s(d, @second, 2)}s"
      end
    end
  end

  defp to_s(d, c, w \\ 2) do
    "#{:io_lib.format("~#{w}..0B", [div(d, c)])}"
  end

  # protocols
  defimpl String.Chars, for: TStamp do
    def to_string(ts = %TStamp{}) do
      ts.dt |> DateTime.to_time() |> Time.truncate(:second) |> Time.to_string()
    end
  end
end
