defmodule Config.Cache do
    use GenServer

    def start_link do

        #start stash
        # when cache is hit, make sure stash is loaded
        pid = Config.Stash.server_process("config_stash_local");
        IO.puts "Starting Config.Cache"


        GenServer.start_link(__MODULE__, nil, name: :config_cache)


    end


    def server_process(config_name) do
      case Config.Server.whereis(config_name) do
        :undefined -> create_server(config_name)
        pid -> pid
      end
    end

    defp create_server(config_name) do
      case Config.ServerSupervisor.start_child(config_name) do
        {:ok, pid} -> pid
        {:error, {:already_started, pid}} -> pid
      end
    end

    # def server_process(config_name) do
    #     #GenServer.call(:config_cache, {:server_process, config_name})
    #     case Config.Server.whereis(config_name) do
    #         :undefined ->
    #             # There's no config server, so we'll issue request to the cache process.
    #             GenServer.call(:config_cache, {:server_process, config_name})
    #
    #         pid -> pid
    #     end
    # end

    def ferror(num) do
        GenServer.call(:config_cache, {:increment_number, num})
    end

    def init(_) do
        # Config.Database.start_link("./persist/")
        {:ok, %{}}
    end

    def handle_call({:server_process, config_name}, _, state) do
        # We need to recheck once again if the server exists.
        config_server_pid = case Config.Server.whereis(config_name) do
            :undefined ->
                {:ok, pid} = Config.ServerSupervisor.start_child(config_name)
                pid

            pid -> pid
        end
        {:reply, config_server_pid, state}
        # case Map.fetch(servers, server_name) do
        #     {:ok, config_server} ->
        #     {:reply, config_server, servers}

        #     :error ->
        #     {:ok, config_server} = Config.Server.start_link(server_name)
        #     {:reply, config_server, Map.put(servers, server_name, config_server) }
        # end
    end

    def handle_cast( {:increment_number, num}, {name, state} ) do
        v = num + 1
        {:reply, state }
    end

    def format_status(_reason, [_pdict, state]) do
        [data: [{'State', "My current state is '#{inspect state}', and I'm happy"}]]
    end
    # Needed for testing purposes
    def handle_info(:stop, state), do: {:stop, :normal, state}
    def handle_info(_, state), do: {:noreply, state}
end
