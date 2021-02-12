defmodule Conmon.Service.HostServer do
  use GenServer

  alias Conmon.Util.L
  alias Conmon.Util.HostStats
  alias Conmon.Util.HostMessage
  alias Conmon.Service.CommandServer

  # Callbacks
  @name HostServer

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: @name)
  end

  def list() do
    GenServer.call(@name, :hinfo)
  end

  def subscribe(pid) do
    GenServer.cast(@name, {:subscribe, pid})
  end

  def add_info(message) do
    GenServer.cast(@name, message)
  end

  def init(_) do
    # state:
    {:ok, %{hs: [], subs: []}}
  end

  def handle_call(:hinfo, state) do
    {:reply, state.hs, state}
  end

  def handle_cast({:subscribe, pid}, s = %{subs: subs}) do
    {:noreply, %{s | subs: [pid | subs]}}
  end

  def handle_cast(hm = %HostMessage{}, state) do
    {:noreply, process_message(hm, state)}
  end

  def handle_call(:hinfo, _from, state) do
    {:reply, state.hs, state}
  end

  def handle_call(_, _from, state) do
    {:reply, nil, state}
  end

  def handle_info(msg, state) do
    IO.puts("handle_info: #{inspect(self())} #{inspect(msg)}")
    {:noreply, state}
  end

  defp process_message(%{ip: ip, rtt: :timeout}, state) do
    L.d("#{ip}: timeout!")
    state
  end

  defp process_message(hm, state) do
    # L.d("process_message: hm: #{hm}, state: #{str(state)}")

    # preserve order by reversing before reconstructing with [a | rest]
    Enum.reverse(state.hs)
    |> Enum.reduce(
      {:new, []},
      fn host_stat, {status, stat_list} ->
        case HostStats.relevant?(host_stat, hm) do
          # add to message
          true ->
            # L.d("Adding #{hm} to #{host_stat}")
            {:done, [HostStats.add_message(host_stat, hm) | stat_list]}

          false ->
            {status, [host_stat | stat_list]}
        end
      end
    )
    |> case do
      {:new, _} -> add_hi(state, hm)
      {:done, host_stat_list} -> %{state | hs: host_stat_list}
    end
  end

  defp str(state) do
    with hs_list <- Enum.map(state.hs, fn s -> to_string(s) end),
         do: "%{hs: #{hs_list}, subs: [?]}"
  end

  defp add_hi(s = %{hs: hi}, hm = %HostMessage{}) do
    # L.d("Adding Host Stat from #{hm}")
    with new_list <- [HostStats.new(hm) | hi] do
      # short term
      start_ping(hm, interval: 0.2, count: 10)
      # long term
      start_ping(hm)
      %{s | hs: Enum.sort_by(new_list, &HostStats.order/1)}
    end
  end

  defp start_ping(%HostMessage{ip: ip}, opts \\ []) do
    CommandServer.ping(ip, opts)
  end
end
