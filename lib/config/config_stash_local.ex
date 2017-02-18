defmodule Config.Stash.Local do
    use GenServer

    #####
    # External API
    def start_link() do
      IO.puts "Starting Config.Stash.Local"
      GenServer.start_link(__MODULE__, nil, name: :config_stash)
    end

    # def start_link(current_number) do
    #     IO.puts "starting stash server "
    #     # {:ok,_pid} = GenServer.start_link( __MODULE__, current_number)
    #     GenServer.start_link(__MODULE__, current_number, :config_stash)
    # end

    def save_value(pid, value) do
        GenServer.cast pid, {:save_value, value}
    end

    

    def get_value(pid, config_name) do
        # GenServer.call(:config_stash, {:get_value, config_name});
        # pid = :global.whereis_name({:config_stash, "config_stash"});
        GenServer.call(pid, {:get_value, config_name});
    end

    def test(pid, val) do
      # GenServer.call(pid, {:test, val})
        # pid = :global.whereis_name({:config_stash, "config_stash"});
        GenServer.call(pid, {:test, val});
    end

    #####
    # GenServer implementation
    #
    def init(_) do
        # need logic to load values from backing store
        #
        # :ets.new(:config_stash_cache, [:set, :named_table, :protected])
        {:ok, nil}
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

    def format_status(_reason, [_pdict, state]) do
        [data: [{'State', "My current state is '#{inspect state}', and I'm happy"}]]
    end
    # Needed for testing purposes
    def handle_info(:stop, state), do: {:stop, :normal, state}
    def handle_info(_, state), do: {:noreply, state}
end
