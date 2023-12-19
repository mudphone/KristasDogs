defmodule Orchestra.System do
  use Supervisor

  alias Orchestra.{
    ProcessRegistry,
    Scheduler
  }

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    children = [
      ProcessRegistry,
      Scheduler.Cron
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
