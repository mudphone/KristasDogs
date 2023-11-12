defmodule KristasDogs.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Run migrations here, since SQLite DB volume may not be ready
    # https://fly.io/docs/elixir/advanced-guides/sqlite3/
    KristasDogs.Release.migrate()

    children = [
      KristasDogsWeb.Telemetry,
      KristasDogs.Repo,
      {Ecto.Migrator,
        repos: Application.fetch_env!(:kristas_dogs, :ecto_repos),
        skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:kristas_dogs, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: KristasDogs.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: KristasDogs.Finch},
      # Start a worker by calling: KristasDogs.Worker.start_link(arg)
      # {KristasDogs.Worker, arg},
      # Start to serve requests, typically the last entry
      KristasDogsWeb.Endpoint,

      # Start Orchestra
      Orchestra.System
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: KristasDogs.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    KristasDogsWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") != nil
  end
end
