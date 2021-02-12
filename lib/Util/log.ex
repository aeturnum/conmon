defmodule Conmon.Util.L do
  require Logger
  # Process.info(self(), :current_stacktrace)



  defp do_log(line, f) do
    f.(line)
    if Mix.env() == :test do
      IO.puts(line)
    end
    line
  end

  # {Conmon.Service.UDPServer, :init, 1, [file: 'lib/Services/udpserver.ex', line: 20]}
  defp trace_line({mod, atom_name, arity, [file: _path, line: line]}), do: "    #{line}| #{mod}.#{atom_name}/#{arity}\n"

  def t(line \\ "") do
    with {_, list} <- Process.info(self(), :current_stacktrace),
         # First two stack frames aren't interesting to us
         {_, useful_list} <- Enum.split(list, 2),
         str_list <- Enum.map(useful_list, &trace_line/1),
         do: d("#{line}:#{str_list}")
  end

  def d(s), do: do_log(s, &Logger.debug/1)
  def e(s), do: do_log(s, &Logger.error/1)
end
