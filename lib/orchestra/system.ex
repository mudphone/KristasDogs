defmodule Orchestra.System do
  use Supervisor

  alias Orchestra.{
    # Cache,
    # Conductor,
    # Metronome,
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
      # Cache,
      # Metronome,
      Scheduler.Cron
      # Conductor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
