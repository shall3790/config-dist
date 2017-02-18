# Starts the to-do system. Assumes that process registry is already started
# and working.

defmodule Config.SystemSupervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, nil, name: :system_supervisor)
  end

  # def start_child(process_name) do
  #   IO.puts "calling start child on system supervisor: "
  #   Supervisor.start_child(:system_supervisor, [process_name])
  # end

  def init(_) do
    # start :pg2  and create our list
    :pg2.start
    :pg2.create({:stash_list, "stash"});
    
    processes = [
      supervisor(Config.Database, ["./persist/"]),
      supervisor(Config.ServerSupervisor, []),
      supervisor(Config.StashSupervisor, []),
      worker(Config.Cache, []),
      # worker(Config.Stash, [])
    ]
    supervise(processes, strategy: :one_for_one)
  end
end
