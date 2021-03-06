defmodule Config.ProcessRegistry do
    use GenServer
    import Kernel, except: [send: 2]

    def start_link do
        IO.puts "Starting process registry"
        GenServer.start_link(__MODULE__, nil, name: :process_registry)
    end

    def register_name(key, pid) do
        GenServer.call(:process_registry, {:register_name, key, pid})
    end

    def whereis_name(key) do
        # GenServer.call(:process_registry, {:whereis_name, key})
        # Lookup is now in the client process without going to the registry.
        case :ets.lookup(:process_registry, key) do
            [{^key, pid}] -> pid;
            _ -> :undefined
        end
    end

    def unregister_name(key) do
        GenServer.call(:process_registry, {:unregister_name, key})
    end

    def send(key, message) do
        case whereis_name(key) do
            :undefined -> {:badarg, {key, message}}
            pid ->
                Kernel.send(pid, message)
                pid
        end
        # case whereis_name(key) do
        #     :undefined -> {:badarg, {key, message}}
        #     pid ->
        #     Kernel.send(pid, message)
        #     pid
        # end
    end


    ########################
    ## INTERNAL 
    ########################
    
    def init(_) do
        :ets.new(:process_registry, [:named_table, :protected, :set])

        # We don't need any state - it is kept in the ETS table which is named
        {:ok, nil}
        # {:ok, HashDict.new}
    end

    def handle_call({:register_name, key, pid}, _, state) do
        if whereis_name(key) != :undefined do
            # Some other process has registered under this alias
            {:reply, :no, state}
        else
            Process.monitor(pid)
            :ets.insert(:process_registry, {key, pid})
            {:reply, :yes, state}
        end
    end

    def handle_call({:unregister_name, key}, _, state) do
        :ets.delete(:process_registry, key)
        {:reply, key, state}
    end


    def handle_info({:DOWN, _, :process, terminated_pid, _}, state) do
        :ets.match_delete(:process_registry, {:_, terminated_pid})
        {:noreply, state}
    end

    def handle_info(_, state), do: {:noreply, state}

    # def handle_call({:register_name, key, pid}, _, process_registry) do
    #     case HashDict.get(process_registry, key) do
    #         nil ->
    #         # Sets up a monitor to the registered process
    #         Process.monitor(pid)
    #         {:reply, :yes, HashDict.put(process_registry, key, pid)}
    #         _ ->
    #         {:reply, :no, process_registry}
    #     end
    # end

    # def handle_call({:whereis_name, key}, _, process_registry) do
    #     {:reply, HashDict.get(process_registry, key, :undefined), process_registry}
    # end

    # def handle_call({:unregister_name, key}, _, process_registry) do
    #     {:reply, key, HashDict.delete(process_registry, key)}
    # end

    # def handle_info({:DOWN, _, :process, pid, _}, process_registry) do
    #     {:noreply, deregister_pid(process_registry, pid)}
    # end

    # def handle_info(_, state), do: {:noreply, state}

    # defp deregister_pid(process_registry, pid) do
    #     # We'll walk through each {key, value} item, and delete those elements whose
    #     # value is identical to the provided pid.
    #     Enum.reduce(
    #         process_registry,
    #         process_registry,
    #         fn
    #         ({registered_alias, registered_process}, registry_acc) when registered_process == pid ->
    #             HashDict.delete(registry_acc, registered_alias)

    #         (_, registry_acc) -> registry_acc
    #         end
    #     )
    # end
end