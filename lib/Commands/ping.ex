defmodule Conmon.Commands.Ping do
  defstruct id: -1, count: -1, interval: 5, loc: nil, ip: nil, task: nil, results: []

  alias Conmon.Commands.Ping
  alias Conmon.Service.HostServer
  alias Conmon.Util.L
  alias Conmon.Util.TStamp
  alias Conmon.Util.HostMessage
  alias Porcelain.Process, as: Proc

  # todo: add cli arguments to the structure and take out things that aren't useful in the handle (results)

  @first_line ~r/PING (?<arg>[\S]*) \((?<ip>[\d.]*)\):/
  @second_line ~r/\d+ bytes from (?<ip>[\d.]+): icmp_seq=(?<seq>\d+) ttl=(?<ttl>\d+) time=(?<rtt>[\d.]+) ms$/
  # @timeout ~r/Request timeout for icmp_seq (?<seq>\d+)/

  def new(id, loc, opts \\ [])

  def new(id, :timeout, _) do
    L.e("Trying to start ping to :timeout!")

    %Ping{loc: nil, id: id}
    |> TStamp.stamp()
  end

  def new(id, loc, opts) do
    %Ping{loc: loc, id: id}
    |> TStamp.stamp()
    |> set_option(opts, :count)
    |> set_option(opts, :interval)
    |> make_task(Keyword.get(opts, :delay, 0))
  end

  defp set_option(p, options, key), do: set_option(p, options, key, Keyword.fetch(options, key))
  defp set_option(p, _options, _key, :error), do: p
  defp set_option(p, _options, key, {:ok, value}), do: Map.put(p, key, value)

  def stop(%Ping{task: %{pid: pid}}), do: send(pid, :stop)

  defp add_response(values, ping), do: %{ping | results: [HostMessage.new(values) | ping.results]}

  def parse_line(p, "Request timeout for icmp_seq " <> seq),
    do: %{"seq" => seq, "ip" => p.ip, "name" => p.loc} |> add_response(p)

  def parse_line(p, line = "PING" <> _) do
    case Regex.named_captures(@first_line, line) do
      %{"ip" => ip, "arg" => _arg} -> %{p | ip: ip}
      _ -> p
    end
  end

  def parse_line(p, line) do
    case Regex.match?(@second_line, line) do
      true ->
        Regex.named_captures(@second_line, line)
        |> Map.merge(%{"name" => p.loc, "ip" => p.ip})
        |> add_response(p)

      _ ->
        p
    end
  end

  # task section where we monitor the command line
  defp make_task(p, delay),
    do: %{
      p
      | task:
          Task.async(fn ->
            L.d("Starting #{p}")
            :timer.sleep(delay)
            do_ping(p)
          end)
    }

  def do_ping(p), do: listen(p, make_p_proc(p))

  defp command_count(%{count: -1}), do: ""
  defp command_count(%{count: c}), do: "-c #{c}"
  defp command_interval(%{interval: -1}), do: ""
  defp command_interval(%{interval: i}), do: "-i #{i}"
  def command(p), do: "ping #{p.loc} #{command_interval(p)} #{command_count(p)}"

  defp make_p_proc(ping = %Ping{}) do
    {:ok, exexec_pid, spawner_os_pid} = Exexec.run(command(ping), stdout: true, stderr: :stdout)
    {exexec_pid, spawner_os_pid}
  end

  # defp make_p_proc(ping = %Ping{}) do
  #   Porcelain.spawn_shell(
  #     # "ping #{ping.loc} -c 4 -i 0.2",
  #     command(ping),
  #     out: {:send, self()},
  #     err: {:send, self()}
  #   )
  # end

  defp listen(ping, pids = {exexec_pid, spawner_os_pid}) do
    # todo: re-write this to be simpler and just re-send messages to ourselves
    receive do
      {:line, line} ->
        parse_line(ping, line)
        |> notify()
        |> listen(pids)

      :stop ->
        Exexec.stop(exexec_pid)

      {:stdout, ^spawner_os_pid, data} ->
        # {^pid, :data, :out, data} ->
        data
        |> IO.inspect(label: "#{ping} stdout")
        |> String.split("\n", trim: true)
        |> Enum.reduce(:ok, fn
          _, :stop ->
            :stop

          "---" <> _, :ok ->
            :stop

          line, :ok ->
            send(self(), {:line, line})
            :ok
        end)

        listen(ping, pids)

      {:stderr, ^spawner_os_pid, data} ->
        # {^pid, :data, :err, data} ->
        # not sure this works
        L.e("#{ping} err: #{data}")
        listen(ping, pids)

      other ->
        # {^pid, :result, _} ->
        L.d("#{ping} over: #{other}")
        {:ok, ping.id}
    end
  end

  defp notify(p = %{results: []}), do: p

  defp notify(p = %{results: [last | _]}) do
    # todo: have this as a callback
    HostServer.add_info(last)
    p
  end

  # protocols
  defimpl String.Chars, for: Ping do
    def to_string(p = %Ping{}) do
      "%Ping[#{p.id}]: #{Ping.command(p)}"
    end
  end
end
