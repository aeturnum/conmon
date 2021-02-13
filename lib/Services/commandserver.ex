defmodule Conmon.Service.CommandServer do
  use GenServer

  alias Conmon.Util.L

  # Callbacks
  @name CommandServer

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: @name)
  end

  def ping(loc, opts \\ []) do
    # L.t("ping #{loc} #{inspect(opts)}")
    GenServer.cast(@name, {:ping, loc, opts})
  end

  def trace(loc) do
    GenServer.cast(@name, {:trace, loc})
  end

  def info(info) do
    GenServer.cast(@name, info)
  end

  def list_traces() do
    GenServer.call(@name, :list_traces)
  end

  def halt() do
    GenServer.call(@name, :stop)
    GenServer.stop(@name, :shutdown, 1000)
  end

  def init(_) do
    {:ok, %{pings: [], traces: [], id: 0}, {:continue, :ok}}
  end

  def terminate(reason, state) do
    L.e("CommandServer.terminate - #{inspect(reason)}, #{inspect(state)}")
    stop_pings(state)
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

  def handle_call(:stop, _from, state) do
    # L.d("handle_call(:stop)")
    state = stop_pings(state)
    {:reply, :ok, state}
  end

  def handle_call(:list_traces, _from, state) do
    # L.d("handle_call(:list_traces)")

    {
      :reply,
      Enum.map(state.traces, fn trc -> trc.loc end),
      state
    }
  end

  def handle_call(arg, _from, state) do
    L.e("CommandServer: Unexpected handle_call: #{inspect(arg)}")
    {:reply, nil, state}
  end

  # down call after tasks are done
  def handle_info({:DOWN, _, :process, _pid, :normal}, s), do: {:noreply, s}

  def handle_info({_ref, {:ok, id}}, state = %{pings: pings}) do
    {:noreply, %{state | pings: Enum.filter(pings, fn p -> p.id != id end)}}
  end

  def handle_info(msg, state) do
    L.e("handle_info: #{inspect(self())} #{inspect(msg)}")
    {:noreply, state}
  end

  def stop_pings(state = %{pings: ps}) do
    # L.e("CommandServer.stop_pings()")
    Enum.each(ps, fn ping -> Conmon.Commands.Ping.stop(ping) end)
    %{state | pings: []}
  end

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
