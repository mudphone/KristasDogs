defmodule Mix.Tasks.BackfillRemovedDogTimestamps do
  @moduledoc """
  One-time backfill correcting `updated_at` for pets whose removal (or
  un-removal) predates the fix to `KristasDogs.Houses.update_removed_dogs/1`
  and `unremove_dog/1`. Those functions used `Repo.update_all`, which
  bypasses Ecto's automatic `updated_at` bump. Any pet removed from the
  website before that fix has a stale `updated_at` that does not reflect
  its real last-changed time.

  Only advances `updated_at` forward to `removed_from_website_at` when
  the latter is more recent. It never moves `updated_at` backward, so a
  pet with a legitimate later update (for example, a details re-scrape)
  is left alone.

      mix backfill_removed_dog_timestamps

  Note: this cannot recover timestamps for pets that were un-removed
  (`removed_from_website_at` cleared back to nil) before this fix. Once
  cleared, there is no stored record of when that happened. Any such
  historical un-removal is not correctable. It only matters if something
  reads `updated_at` to infer freshness, as the dots cache does. It
  self-heals the moment that pet is touched again.
  """

  use Mix.Task

  import Ecto.Query

  alias KristasDogs.Repo
  alias KristasDogs.Houses.Pet

  @shortdoc "Backfills updated_at for pets removed before update_all bumped it"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")
    {count, _} = call()
    Mix.shell().info("Backfill complete: #{count} pet(s) updated.")
  end

  @doc """
  Runs the backfill itself, separated from `run/1` so tests can call it
  directly without going through `Mix.Task.run("app.start")`, which
  doesn't play well with the Ecto SQL sandbox in tests.
  """
  def call do
    from(p in Pet,
      where: not is_nil(p.removed_from_website_at) and p.removed_from_website_at > p.updated_at,
      update: [set: [updated_at: p.removed_from_website_at]]
    )
    |> Repo.update_all([])
  end
end
