defmodule Config.Stash do
    use GenServer

    def start_link(name) do
        IO.puts "Starting Config.Stash (name= #{name})"

        #Local process startup
        #GenServer.start_link(__MODULE__, nil, name: :config_stash)

        {:ok, pid} = GenServer.start_link(__MODULE__, name, name: via_tuple(name))
        # global startup


        # {:ok, pid} = GenServer.start_link(
        #   __MODULE__, name, name: {:global, {:config_stash, name}}
        # )
    end

    def whereis(name) do
        #Config.ProcessRegistry.whereis_name({:config_server, name})

        # gproc lookup example
        :gproc.whereis_name({:n, :l, {:stash_server, name}})

        # using :global lookup
        # :global.whereis_name({:config_server, name})
    end

    defp via_tuple(name) do
        #{:via, Config.ProcessRegistry, {:config_server, name}}
        {:via, :gproc, {:n, :l, {:stash_server, name}}}
    end

    def server_process(stash_name) do
      # case :global.whereis_name({:config_stash, stash_name}) do
      #   :undefined -> create_server(stash_name)
      #   pid -> pid
      # end
        case Config.Stash.whereis(stash_name) do
              :undefined ->
                  # There's no config server, so we'll issue request to the cache process.
                  #GenServer.call(:config_cache, {:server_process, config_name})
                  create_server(stash_name)
              pid -> pid
        end
    end
    #
    defp create_server(stash_name) do
      case Config.StashSupervisor.start_child(stash_name) do
        {:ok, pid} ->
          # join pg2 group across cluster
          :pg2.join({:stash_list, "stash"}, pid)
          pid
        {:error, {:already_started, pid}} -> pid
      end
    end

    def save_value(pid, value) do
        GenServer.cast(pid, {:save_value, value});
    end

    def get_value(pid, config_name) do
        # GenServer.call(:config_stash, {:get_value, config_name});
        # pid = :global.whereis_name({:config_stash, "config_stash"});
        GenServer.call(pid, {:get_value, config_name});
    end

    def test2(value) do
        IO.puts "called test2 with " <> value
    end

    def test(pid, val) do
      # GenServer.call(pid, {:test, val})
        # pid = :global.whereis_name({:config_stash, "config_stash"});
        GenServer.call(pid, {:test, val});
    end

    # defp create_server(stash_name) do
    #   # case Config.SystemSupervisor.start_child(name) do
    #   #   {:ok, pid} -> pid
    #   #   {:error, {:already_started, pid}} -> pid
    #   # end
    #   case GenServer.start_link(__MODULE__, stash_name, name: {:global, {:config_stash, stash_name}}) do
    #     {:ok, pid} -> pid
    #     {:error, {:already_started, pid}} -> pid
    #   end
    # end

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

    #####
    # GenServer implementation
    #
    def init(_) do
        # need logic to load values from backing store
        #
        IO.puts "Config.Stash init... creating ETS table"
        :ets.new(:config_stash_cache, [:set, :named_table, :protected])
        {:ok, nil}
    end

    def handle_call( {:test2, val}, _from, current_val) do
      IO.puts "Config.Stash test2 call, value: " <> val;
      {:reply, nil, current_val}
    end

    def handle_call( {:test, val}, _from, current_val ) do
        IO.puts "stash server - test call: "
        { config_name, config_values  } = val
        IO.inspect config_values
        IO.puts "saving state in ETS for config: " <> config_name
        # save values in ETS
        :ets.insert(:config_stash_cache, {config_name, config_values})

        {:reply, nil, current_val }
    end

    def handle_call({:get_value, config_name}, _from, current_value) do
        # :ets.lookup(:config_stash_cache, config_name)
        case :ets.lookup(:config_stash_cache, config_name) do
          [{^config_name, values}] -> {:reply, values, current_value}
          [] -> {:reply, nil, current_value}
        end
        # { :reply, values, current_value }
    end

    def handle_cast({:save_value, value}, _current_value) do
        { :noreply, value}
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
