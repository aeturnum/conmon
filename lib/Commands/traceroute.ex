defmodule Conmon.Commands.Traceroute do
  defstruct id: -1, loc: nil, ip: nil, name: nil, task: nil, hops: []

  alias Conmon.Commands.Traceroute
  alias Conmon.Service.HostServer
  alias Conmon.Util.L
  alias Conmon.Util.TStamp
  alias Conmon.Util.HostMessage
  # alias Porcelain.Process, as: Proc

  #   traceroute to www.google.com (172.217.6.68), 64 hops max, 52 byte packets
  #  1  192.168.1.1 (192.168.1.1)  4.020 ms
  #  2  lo0.bras1.bklyca01.sonic.net (157.131.132.4)  8.902 ms
  #  3  157-131-194-66.static.sonic.net (157.131.194.66)  19.941 ms
  #  4  0.ae7.cr2.rcmdca11.sonic.net (198.27.244.193)  18.880 ms
  #  5  0.ae2.cr1.rcmdca11.sonic.net (157.131.209.129)  9.642 ms
  #  6  *
  #  7  100.ae1.nrd1.equinix-sj.sonic.net (75.101.33.185)  8.202 ms
  #  8  74.125.118.6 (74.125.118.6)  7.470 ms
  #  9  74.125.118.6 (74.125.118.6)  6.997 ms
  # 10  209.85.248.35 (209.85.248.35)  8.103 ms
  # 11  sfo07s17-in-f4.1e100.net (172.217.6.68)  6.790 ms

  # @first_line ~r/PING (?<arg>[\S]*) \((?<ip>[\d.]*)\):/
  @first_line ~r/traceroute to (?<arg>[\S]*) \((?<ip>[\d.]*)\), \d+ hops max, \d+ byte packets$/
  @hop_line ~r/(?<hop>[\d]+)\s+(?<name>[\S]*) \((?<ip>[\d.]*)\)\s+(?<rtt>[\d.]+) ms/
  # @second_line ~r/\d+ bytes from (?<ip>[\d.]+): icmp_seq=(?<seq>\d+) ttl=(?<ttl>\d+) time=(?<time>[\d.]+) ms$/
  @timeout ~r/(?<hop>[\d]+)\s+\*/

  def new(id, loc, delay \\ 0) do
    %Traceroute{id: id, loc: loc}
    |> TStamp.stamp()
    |> make_task(delay)
  end

  def stop(%Traceroute{task: %{pid: pid}}), do: send(pid, :stop)

  def parse_line(p, line = "traceroute to" <> _) do
    case Regex.named_captures(@first_line, line) do
      %{"ip" => ip, "arg" => _arg} -> %{p | ip: ip}
      _ -> p
    end
  end

  def parse_line(trace, line) do
    case Regex.match?(@hop_line, line) do
      true ->
        Regex.named_captures(@hop_line, line) |> add_response(trace)

      _ ->
        case Regex.match?(@timeout, line) do
          true -> Regex.named_captures(@timeout, line) |> add_response(trace)
          _ -> trace
        end
    end
  end

  defp add_response(map, trace), do: %{trace | hops: [HostMessage.new(map) | trace.hops]}

  # task section where we monitor the command line
  defp make_task(tr, delay),
    do: %{
      tr
      | task:
          Task.async(fn ->
            :timer.sleep(delay)
            do_traceroute(tr)
          end)
    }

  def do_traceroute(tr) do
    listen(tr, make_p_proc(tr))
  end

  # defp make_p_proc(tr = %Traceroute{}) do
  #   Porcelain.spawn_shell(
  #     "traceroute -q 1 #{tr.loc}",
  #     out: {:send, self()},
  #     err: {:send, self()}
  #   )
  # end

  defp make_p_proc(tr = %Traceroute{}) do
    {:ok, exexec_pid, spawner_os_pid} = Exexec.run("traceroute -q 1 #{tr.loc}", stdout: true, stderr: :stdout)
    {exexec_pid, spawner_os_pid}
  end

  defp listen(tr, pid = {exexec_pid, spawner_os_pid}) do
    # todo: re-write this to be simpler and just re-send messages to ourselves
    receive do
      {:line, line} ->
        parse_line(tr, line)
        # |> IO.inspect(label: "tace line")
        |> notify()
        |> listen(pid)

      :stop ->
        Exexec.stop(exexec_pid)
        # Proc.signal(proc, :int)
        {:stdout, ^spawner_os_pid, data} ->

      # {^pid, :data, :out, data} ->
        data
        |> L.d()
        # |> IO.inspect(label: "trace")
        |> String.split("\n", trim: true)
        |> Enum.each(fn line -> send(self(), {:line, line}) end)

        listen(tr, pid)

        {:stderr, ^spawner_os_pid, data} ->
      # {^pid, :data, :err, data} ->
        # not sure this works
        L.e("Trace #{tr.id} err: #{data}")
        listen(tr, pid)

      {^pid, :result, _} ->
        L.d("trace #{tr.id} over")
        {:ok, tr.id}
    end
  end

  defp heartbeat(p) do
    # IO.puts("ts: #{last_ts(p)}")
    p
  end

  defp notify(p = %{hops: []}), do: p

  defp notify(p = %{hops: [last | _]}) do
    # todo: callback?
    L.d("trace.notify -P ICMP #{last}")
    HostServer.add_info(last)
    p
  end

  # protocols
  defimpl String.Chars, for: Traceroute do
    def to_string(p = %Traceroute{}) do
      "%Trace[#{p.id}]: #{p.loc}(#{p.ip}) - #{length(p.hops)}"
    end
  end
end
