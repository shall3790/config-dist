defmodule Config.StashSupervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil, name: :stash_supervisor)

    
  end

  def start_child(stash_name) do
    IO.puts "stash_supervisor start_child call"
    Supervisor.start_child(:stash_supervisor, [stash_name])
  end

  def init(_) do
    IO.puts "stash_supervisor init"
    supervise([worker(Config.Stash, [])], strategy: :simple_one_for_one)
  end
end
