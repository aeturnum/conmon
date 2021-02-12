defmodule Conmon.Util.HostStats do
  defstruct order: -1, label: nil, names: [], ips: [], latencies: [], timeouts: 0

  alias Conmon.Util.HostStats
  alias Conmon.Util.HostMessage

  # @ipregex ~r/\d+\.\d+\.\d+\.\d+/

  def new(hm = %HostMessage{}) do
    %HostStats{
      label: hm.name,
      names: [hm.name],
      ips: [hm.ip],
      order: HostMessage.get_ordinal(hm)
    }
    |> add_message(hm)
  end

  def order(%HostStats{order: order}), do: order

  # todo: decide how to think about name / ip duality
  # names can have many ips but ips only have one name at a time
  def add_message(hs, hm) do
    case relevant?(hs, hm) do
      true ->
        %{
          hs
          | names: merge_str(hs.names, hm.name),
            ips: merge_str(hs.ips, hm.ip),
            latencies: [hm_to_lat(hm) | hs.latencies]
        }

      false ->
        hs
    end
  end

  defp hm_to_lat(%{rtt: r, ts: ts}), do: {ts, r}

  defp merge_str(list, new) do
    case Enum.member?(list, new) do
      true -> list
      false -> [new | list]
    end
  end

  def relevant?(_, %{name: :timeout}), do: false
  def relevant?(_, %{ip: :timeout}), do: false
  def relevant?(hs, hm), do: Enum.member?(hs.names, hm.name) || Enum.member?(hs.ips, hm.ip)

  def message(source, name, ip, ts, latency), do: {:hinfo, {source, name, ip, ts, latency}}

  def ip(%HostStats{ips: [ip | _]}), do: ip
  def ip(%HostStats{ips: []}), do: "?"

  def pings(%HostStats{latencies: l}), do: Enum.map(l, fn {_ts, lat} -> lat end)

  def last_ping(%HostStats{latencies: []}), do: nil
  def last_ping(%HostStats{latencies: [last | _]}), do: last

  def top_ping(%HostStats{latencies: []}), do: nil

  def top_ping(%HostStats{latencies: l}) do
    Enum.reduce(l, fn p, acc -> ping_max(p, acc) end)
  end

  def bottom_ping(%HostStats{latencies: []}), do: nil

  def bottom_ping(%HostStats{latencies: l}),
    do: Enum.reduce(l, fn p, acc -> ping_min(p, acc) end)

  # versions from when there was a source field
  # defp ping_min(a = {_, _, lat_a}, {_, _, lat_b}) when lat_a < lat_b, do: a
  # defp ping_min({_, _, lat_a}, b = {_, _, lat_b}) when lat_a >= lat_b, do: b
  # defp ping_max(a = {_, _, lat_a}, {_, _, lat_b}) when lat_a > lat_b, do: a
  # defp ping_max({_, _, lat_a}, b = {_, _, lat_b}) when lat_a <= lat_b, do: b

  def ping_string(nil), do: ""
  # def ping_string({_, _, latency}), do: "#{:io_lib.format("~6.2.0f", [latency])}ms"
  # def ping_string({_, _, latency}), do: "#{:io_lib.format("~.2f", [latency])}ms"
  # def ping_string({_, _, latency}), do: "#{Float.round(latency, 2)}ms"
  def ping_string({_, latency}), do: "#{Float.round(latency, 2)}ms"

  defp ping_min(a = {_, lat_a}, {_, lat_b}) when lat_a < lat_b, do: a
  defp ping_min({_, lat_a}, b = {_, lat_b}) when lat_a >= lat_b, do: b
  defp ping_max(a = {_, lat_a}, {_, lat_b}) when lat_a > lat_b, do: a
  defp ping_max({_, lat_a}, b = {_, lat_b}) when lat_a <= lat_b, do: b

  def average_ping(%HostStats{latencies: []}), do: nil

  def average_ping(%HostStats{latencies: lats}) do
    # pull out rtts
    sum = Enum.map(lats, fn e -> elem(e, 1) end) |> Enum.sum()
    # add them up
    # divide them
    {nil, sum / length(lats)}
  end

  def str_pings(%HostStats{latencies: l}),
    do: Enum.map(l, fn {ts, lat} -> "#{ts}|#{lat}ms" end)

  defimpl String.Chars, for: HostStats do
    def to_string(h = %HostStats{}) do
      # "%HostStats[#{h.label}] - #{inspect(HostStats.str_pings(h))}"
      "%HS[#{h.order}][#{h.label}] - #{length(h.latencies)}"
    end
  end
end
