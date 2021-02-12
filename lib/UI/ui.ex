defmodule Conmon.UI do
  @behaviour Ratatouille.App

  import Ratatouille.View
  alias Conmon.Util.L
  alias Conmon.Service.CommandServer
  alias Conmon.Service.HostServer
  alias Ratatouille.Runtime.Subscription
  # alias Ratatouille.Constants
  alias Conmon.Util.HostStats

  def init(_context) do
    %{target: "?", hosts: []}
  end

  def update(model, msg) do
    case msg do
      :tick ->
        new_hosts = HostServer.list()
        # L.d("update.tick: #{inspect(Enum.map(new_hosts, &to_string/1))}")
        %{model | hosts: new_hosts}

      _ ->
        model
    end
  end

  def subscribe(_model) do
    Subscription.interval(100, :tick)
  end

  defp time_color({_, rtt}) when rtt < 50, do: :green
  defp time_color({_, rtt}) when rtt < 150, do: :yellow
  defp time_color({_, _}), do: :red
  defp time_color(nil), do: :black

  defp mlababel(hi) do
    with min <- HostStats.bottom_ping(hi),
         max <- HostStats.top_ping(hi),
         avg <- HostStats.average_ping(hi) do
      label do
        text(content: "[")
        text(content: "min:#{HostStats.ping_string(min)}", color: time_color(min))
        text(content: "|")
        text(content: "max:#{HostStats.ping_string(max)}", color: time_color(max))
        text(content: "|")
        text(content: "avg:#{HostStats.ping_string(avg)}", color: time_color(avg))
        text(content: "]")
      end
    end
  end

  defp host_latency(hi) do
    color = time_color(HostStats.average_ping(hi))

    panel(title: "<#{HostStats.order(hi)} -> #{hi.label}>", height: 4, color: color) do
      row do
        column size: 9 do
          mlababel(hi)
        end

        column size: 3 do
          # sparkline(series: HostStats.pings(hi))
          # chart(type: :line, series: HostInfo.pings(hi), height: 10)
        end
      end
    end
  end

  def render(state = %{target: tgt}) do
    top_bar =
      bar do
        label(content: "Route to #{tgt}")
      end

    view top_bar: top_bar do
      for host_stat <- state.hosts do
        row do
          column size: 3 do
            host_latency(host_stat)
          end

          column size: 9 do
          end
        end
      end
    end
  end
end
