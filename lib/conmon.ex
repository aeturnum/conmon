defmodule Conmon do
  use Application

  def start(_type, _args) do
    # don't run if we're testing

    Supervisor.start_link(
      children(),
      strategy: :one_for_one,
      name: Conmon.Supervisor
    )
  end

  def children() do
    runtime_opts = [
      app: Conmon.UI,
      shutdown: {:application, :conmon}
    ]

    case Mix.env() do
      :test ->
        [{Conmon.Service.CommandServer, []}, {Conmon.Service.HostServer, []}]

      _ ->
        [
          {Ratatouille.Runtime.Supervisor, runtime: runtime_opts},
          {Conmon.Service.CommandServer, []},
          {Conmon.Service.HostServer, []}
        ]
    end
  end

  def stop(_state) do
    # Do a hard shutdown after the application has been stopped.
    #
    # Another, perhaps better, option is `System.stop/0`, but this results in a
    # rather annoying lag when quitting the terminal application.
    System.halt()
  end
end
