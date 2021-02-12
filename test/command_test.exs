defmodule ConmonTest.Commands do
  use ExUnit.Case
  doctest Conmon

  test "ping" do
    Conmon.Service.CommandServer.ping("www.google.com")
    :timer.sleep(1000)
    Conmon.Service.CommandServer.halt()
    :timer.sleep(1000)
  end

  # test "trace" do
  #   Conmon.Service.CommandServer.trace("www.google.com")
  #   :timer.sleep(2000)
  #   # Conmon.Monitors.CommandServer.halt()
  #   :timer.sleep(1000)
  # end
end
