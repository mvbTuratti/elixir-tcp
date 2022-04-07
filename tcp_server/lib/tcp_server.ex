defmodule TcpServer do
  require Logger

  def accept(port) do
    # The options below mean:
    #
    # 1. `:binary` - receives data as binaries (instead of lists)
    # 2. `packet: :line` - receives data line by line
    # 3. `active: false` - blocks on `:gen_tcp.recv/2` until data is available
    # 4. `reuseaddr: true` - allows us to reuse the address if the listener crashes
    #
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(TcpServer.TaskSupervisor, fn -> serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    msg =
      with {:ok, data} <- read_line(socket, <<>>),
           {:ok, command} <- TcpServer.Command.parse(data),
           do: TcpServer.Command.run(command)
    write_line(socket, msg)
    serve(socket)
  end

  defp read_line(socket, acc) do
    {_, a} = line = :gen_tcp.recv(socket, 0)

    case line do
      {:ok, <<"\r\n">>} -> {:ok, acc}
      {:ok, _} -> read_line(socket, acc <> a)
      {:error, reason} -> {:error, reason}
    end
  end

  defp write_line(socket, {:ok, text}) do

    :gen_tcp.send(socket, text)
    #:timer.sleep(5000)
    :gen_tcp.close(socket)
  end

  defp write_line(socket, {:error, :unknown_command}) do
    :gen_tcp.close(socket)
  end

  defp write_line(_socket, {:error, :closed}) do
    # The connection was closed, exit politely
    exit(:shutdown)
  end

end
