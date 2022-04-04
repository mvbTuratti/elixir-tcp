defmodule TcpServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    port = String.to_integer(System.get_env("PORT") || "6789")
    children = [
      {Task.Supervisor, name: TcpServer.TaskSupervisor},
      Supervisor.child_spec({Task, fn -> TcpServer.accept(port) end}, restart: :permanent)
    ]

    opts = [strategy: :one_for_one, name: TcpServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
