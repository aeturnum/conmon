defmodule Conmon.Util.HostMessage do
  defstruct name: :timeout, ip: :timeout, rtt: :timeout, tags: []

  alias Conmon.Util.HostMessage
  alias Conmon.Util.TStamp

  def new(name, ip, rtt, tags \\ []) do
    %HostMessage{name: name, ip: ip, rtt: rtt, tags: tags}
    |> TStamp.stamp()
  end

  def new(map) do
    new_from_map(%HostMessage{}, Map.to_list(map))
    |> TStamp.stamp()
  end

  def get_ordinal(%{tags: tags}) do
    tags
    |> Enum.reduce_while(
      0,
      fn
        {:hop, h}, _ -> {:halt, h}
        {:seq, s}, _ -> {:halt, s}
        _, v -> {:cont, v}
      end
    )
  end

  def get_ordinal(_), do: 0

  defp new_from_map(hm, []), do: hm
  defp new_from_map(hm, [{"name", n} | rest]), do: %{hm | name: n} |> new_from_map(rest)
  defp new_from_map(hm, [{"loc", n} | rest]), do: %{hm | name: n} |> new_from_map(rest)
  defp new_from_map(hm, [{"ip", ip} | rest]), do: %{hm | ip: ip} |> new_from_map(rest)
  defp new_from_map(hm, [{"rtt", rtt} | rest]), do: %{hm | rtt: float(rtt)} |> new_from_map(rest)
  defp new_from_map(hm, [{"seq", seq} | rest]), do: add_tag(hm, :seq, int(seq)) |> new_from_map(rest)
  defp new_from_map(hm, [{"hop", h} | rest]), do: add_tag(hm, :hop, int(h)) |> new_from_map(rest)
  defp new_from_map(hm, [{"source", s} | rest]), do: add_tag(hm, :source, s) |> new_from_map(rest)
  defp new_from_map(hm, [_ | rest]), do: new_from_map(hm, rest)

  defp add_tag(hm, tag, v), do: %{hm | tags: [{tag, v} | hm.tags]}

  defp int(i) when is_integer(i), do: i
  defp int(i) when is_binary(i), do: Integer.parse(i) |> elem(0)
  defp float(f) when is_float(f), do: f
  defp float(f) when is_binary(f), do: Float.parse(f) |> elem(0)

  # def message(source, name, ip, ts, latency), do: {:hinfo, {source, name, ip, ts, latency}}

  def tag_badge(%{tags: tags}), do: tag_badge(tags)
  def tag_badge([]), do: ""
  def tag_badge([tag | rest]), do: "#{tag_string(tag)}#{tag_badge(rest)}"
  defp tag_string({:source, id}), do: "[#{id}<]"
  defp tag_string({:seq, s}), do: "[#{s}]"
  defp tag_string({:hop, num}), do: "<#{num}>"

  def rtt_str(%{rtt: :timeout}), do: "*"
  def rtt_str(%{rtt: rtt}) when is_float(rtt), do: "#{Float.round(rtt, 2)}"

  defimpl String.Chars, for: HostMessage do
    def to_string(h = %HostMessage{}) do
      "%HM#{HostMessage.tag_badge(h)}[#{h.ip}]:#{HostMessage.rtt_str(h)}ms"
    end
  end
end
