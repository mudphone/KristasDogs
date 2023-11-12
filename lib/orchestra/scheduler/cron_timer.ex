defmodule Orchestra.Scheduler.CronTimer do
  use GenServer

  require Logger

  alias KristasDogs.Scrape
  alias Orchestra.ProcessRegistry

  @tick_millis :timer.minutes(15)
  # @tick_millis :timer.seconds(5)

  def start_link(worker_id) do
    IO.puts("Starting CronTimer #{worker_id}")

    GenServer.start_link(
      __MODULE__,
      nil,
      name: via_tuple(worker_id)
    )
  end

  # def get(worker_id, key) do
  #   GenServer.call(via_tuple(worker_id), {:get, key})
  # end

  # def get_live_sim_ids(worker_id) do
  #   get(worker_id, :live_sim_ids)
  # end

  defp via_tuple(worker_id) do
    ProcessRegistry.via_tuple({__MODULE__, worker_id})
  end

  @impl GenServer
  def init(_) do
    send(self(), :tick)
    {:ok, %{}}
  end

  @impl GenServer
  def handle_info(:tick, state) do
    Logger.debug("Do work")
    Scrape.record_dogs()

    Process.send_after(self(), :tick, @tick_millis)
    {:noreply, state}
  end

  # @impl GenServer
  # def handle_cast({:store, key, data}, db_folder) do
  #   db_folder
  #   |> file_name(key)
  #   |> File.write!(:erlang.term_to_binary(data))

  #   {:noreply, db_folder}
  # end

  # @impl GenServer
  # def handle_call({:get, key}, _, state) do
  #   {:reply, Map.get(state, key), state}
  # end
end
