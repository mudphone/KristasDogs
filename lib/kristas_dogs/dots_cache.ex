defmodule KristasDogs.DotsCache do
  @moduledoc """
  Small in-memory cache (ETS backed, process lifetime only, never
  persisted) for the /api/stats/dots/* JSON responses. Without this,
  every request, even one that ends in a 304, pays for the full
  DogStats query, ChartGeometry layout, JSON encode, and SHA-256 hash
  just to check if the chart's data changed. `fetch/3` skips all of
  that on a cache hit.

  Disabled in :test (see config/test.exs). This cache is a single
  process-global cache. It lives outside Ecto's per-test sandbox
  transaction. Without disabling it, one test's cached response could
  leak into a different test that happens to compute the same cheap
  `version` (most commonly: two tests both see an empty, no-dogs
  database before their own fixture is inserted).
  """

  use GenServer

  @table :dots_cache

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Returns `{body, etag}` for `key`. If caching is enabled and the
  cached entry's stored version matches `version_fn.()`, returns the
  cached value without calling `compute_fn`. Otherwise (cache disabled,
  cache miss, or a version mismatch) calls `compute_fn.()`, which must
  return `{body, etag}`, and, if caching is enabled, stores the result
  under the fresh version before returning it.
  """
  def fetch(key, version_fn, compute_fn) do
    if enabled?() do
      version = version_fn.()

      case :ets.lookup(@table, key) do
        [{^key, ^version, body, etag}] ->
          {body, etag}

        _ ->
          {body, etag} = compute_fn.()
          :ets.insert(@table, {key, version, body, etag})
          {body, etag}
      end
    else
      compute_fn.()
    end
  end

  defp enabled? do
    Application.get_env(:kristas_dogs, :dots_cache_enabled, true)
  end

  @impl true
  def init(_opts) do
    :ets.new(@table, [:set, :named_table, :public, read_concurrency: true])
    {:ok, %{}}
  end
end
