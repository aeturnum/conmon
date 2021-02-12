defmodule ConmonTest.InternalIpc do
  use ExUnit.Case
  doctest Conmon

  alias Conmon.Util.HostMessage

  test "message" do
    name = "www.google.com"
    ip = "216.58.194.196"
    rtt = {"14.12", 14.12}
    hop = {"3", 3}
    hm = HostMessage.new(%{"loc" => name, "ip" => ip, "rtt" => elem(rtt, 0), "hop" => elem(hop, 0)})
    assert hm.name == name
    assert hm.ip == ip
    assert hm.rtt == elem(rtt, 1)
    assert Keyword.has_key?(hm.tags, :hop)
    assert Keyword.get(hm.tags, :hop) == elem(hop, 1)
  end
end
