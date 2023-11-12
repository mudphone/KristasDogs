defmodule Orchestra.Scheduler.Cron do
  alias Orchestra.Scheduler.CronTimer

  def start_link do
    children = [worker_spec(:dog_fetcher)]
    Supervisor.start_link(children, name: __MODULE__, strategy: :one_for_one)
  end

  defp worker_spec(worker_id) do
    the_worker_spec = {CronTimer, worker_id}
    Supervisor.child_spec(the_worker_spec, id: worker_id)
  end

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end

  # def get(key) do
  #   ConductorWaker.get(@default_worker_id, key)
  # end

  # def get_live_sim_ids() do
  #   ConductorWaker.get_live_sim_ids(@default_worker_id)
  # end
end
