defmodule Conmon.MixProject do
  use Mix.Project

  def project do
    [
      app: :conmon,
      version: "0.0.1",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      default_task: "app",
      preferred_cli_env: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
      escript: [main_module: Conmon.UI.Cli, embed_elixir: true]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Conmon, []},
      extra_applications: [:logger, :exexec]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ratatouille, "~> 0.5.0"},
      {:exexec, "~> 0.2"},
      {:logger_file_backend, "~> 0.0.11"},
      {:optimus, "~> 0.1.0"},
      {:excoveralls, "~> 0.13", only: :test}

      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
