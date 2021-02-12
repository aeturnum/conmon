defmodule Mix.Tasks.App do
  use Mix.Task

  @impl Mix.Task
  def run(args) do
    Mix.Tasks.Run.run(["--no-halt"] ++ args)
  end
end
