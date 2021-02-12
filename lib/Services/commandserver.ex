defmodule Conmon.Service.CommandServer do
  use GenServer

  alias Conmon.Util.L

  # Callbacks
  @name CommandServer

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: @name)
  end

  def ping(loc, opts \\ []) do
    L.t("ping #{loc} #{inspect(opts)}")
    GenServer.cast(@name, {:ping, loc, opts})
  end

  def trace(loc) do
    GenServer.cast(@name, {:trace, loc})
  end

  def info(info) do
    GenServer.cast(@name, info)
  end

  def halt() do
    GenServer.cast(@name, :stop)
  end

  def init(_) do
    {:ok, %{pings: [], traces: [], id: 0}, {:continue, :ok}}
  end

  def handle_continue(_, state) do
    trace("www.google.com")
    {:noreply, state}
  end

  def handle_cast({:ping, remote_location, opts}, state) do
    {:noreply, state |> add_ping(remote_location, opts)}
  end

  def handle_cast({:trace, remote_location}, state) do
    {:noreply, state |> add_trace(remote_location)}
  end

  def handle_cast(:stop, state) do
    stop_pings(state)
    {:noreply, state}
  end

  def handle_call(_, _from, state) do
    {:reply, nil, state}
  end

  # down call after tasks are done
  def handle_info({:DOWN, _, :process, _pid, :normal}, s), do: {:noreply, s}

  def handle_info({_ref, {:ok, id}}, state = %{pings: pings}) do
    {:noreply, %{state | pings: Enum.filter(pings, fn p -> p.id != id end)}}
  end

  def handle_info(msg, state) do
    # IO.puts("handle_info: #{inspect(self())} #{inspect(msg)}")
    {:noreply, state}
  end

  def stop_pings(%{pings: ps}),
    do: ps |> Enum.each(fn ping -> Conmon.Commands.Ping.stop(ping) end)

  defp add_trace(s = %{traces: trs, id: id}, loc, delay \\ 0) do
    %{
      s
      | traces: [Conmon.Commands.Traceroute.new(id, loc, delay) | trs],
        id: id + 1
    }
  end

  defp add_ping(s = %{pings: ps, id: id}, loc, opts) do
    %{
      s
      | pings: [Conmon.Commands.Ping.new(id, loc, opts) | ps],
        id: id + 1
    }
  end
end
