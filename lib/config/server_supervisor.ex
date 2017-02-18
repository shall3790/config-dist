defmodule Config.ServerSupervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil, name: :config_server_supervisor)

  end

  def start_child(config_name) do
    IO.puts "server supervisor start_child call"
    Supervisor.start_child(:config_server_supervisor, [config_name])
  end

  def init(_) do
    IO.puts "server supervisor init"
    supervise([worker(Config.Server, [])], strategy: :simple_one_for_one)
  end
end
