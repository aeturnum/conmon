defmodule Conmon.UI.Cli do
  def main(argv) do
    options =
      Optimus.new!(
        name: "conmon",
        description: "Connection monitor",
        version: "0.0.1",
        author: "Drex aeturnum@gmail.com",
        about: "Utility for tracking latency to a set of hosts",
        allow_unknown_args: false,
        parse_double_dash: true,
        args: [
          target: [
            value_name: "REMOTE_HOST",
            help: "Remote location to monitor your path to",
            required: true,
            parser: :string
          ]
        ],
        flags: [
          # print_header: [
          #   short: "-h",
          #   long: "--print-header",
          #   help: "Specifies wheather to print header before the outputs",
          #   multiple: false
          # ],
          # verbosity: [
          #   short: "-v",
          #   help: "Verbosity level",
          #   multiple: true
          # ]
        ]
      )
      |> Optimus.parse!(System.argv())

    Conmon.Service.CommandServer.trace(options.args.target)
  end
end
