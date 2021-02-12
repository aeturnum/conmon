defmodule ConmonTest do
  use ExUnit.Case
  doctest Conmon

  alias Conmon.Util.TStamp
  # easier to test
  @second 1000
  @minute @second * 60
  @hour @minute * 60
  @day @hour * 24

  # test "parse 2" do
  #   Conmon.Commands.Ping.parse_line(
  #     %Conmon.Commands.Ping{},
  #     "64 bytes from 172.217.6.68: icmp_seq=0 ttl=116 time=16.897 ms"
  #   )
  #   |> IO.inspect()
  # end

  # test "parse 1" do
  #   Conmon.Commands.Ping.parse_line(
  #     %Conmon.Commands.Ping{},
  #     "PING www.google.com (172.217.6.68): 56 data bytes"
  #   )
  #   |> IO.inspect()
  # end

  test "time" do
    assert TStamp.timestring(1400) == "01.400s"
    assert TStamp.timestring(400) == "0.400s"
    assert TStamp.timestring(2000) == "02s"

    assert TStamp.timestring(200 * @day + 12 * @hour + 54 * @minute + 30 * @second) ==
             "200D, 12h:54m:30s"
  end
end
