defmodule Config.Database do
    @pool_size 3

    def start_link(db_folder) do
        Config.PoolSupervisor.start_link(db_folder, @pool_size)
    end

    def store(key, data) do
        key
        |> choose_worker
        |> Config.DatabaseWorker.store(key, data)
    end

    def get(key) do
        key
        |> choose_worker
        |> Config.DatabaseWorker.get(key)
    end

    defp choose_worker(key) do
        :erlang.phash2(key, @pool_size) + 1
    end
end