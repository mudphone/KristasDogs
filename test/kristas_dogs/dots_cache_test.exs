defmodule KristasDogs.DotsCacheTest do
  use ExUnit.Case, async: false

  alias KristasDogs.DotsCache

  setup do
    previous = Application.get_env(:kristas_dogs, :dots_cache_enabled)
    Application.put_env(:kristas_dogs, :dots_cache_enabled, true)

    on_exit(fn ->
      if previous == nil do
        Application.delete_env(:kristas_dogs, :dots_cache_enabled)
      else
        Application.put_env(:kristas_dogs, :dots_cache_enabled, previous)
      end
    end)

    :ok
  end

  defp counting_compute_fn(agent, result) do
    fn ->
      Agent.update(agent, &(&1 + 1))
      result
    end
  end

  test "cache miss: compute_fn is called and its result is returned" do
    {:ok, agent} = Agent.start_link(fn -> 0 end)
    key = :dots_cache_test_miss

    result = DotsCache.fetch(key, fn -> 1 end, counting_compute_fn(agent, {"body", "etag"}))

    assert result == {"body", "etag"}
    assert Agent.get(agent, & &1) == 1
  end

  test "cache hit: compute_fn is not called again on a second request with the same version" do
    {:ok, agent} = Agent.start_link(fn -> 0 end)
    key = :dots_cache_test_hit

    first = DotsCache.fetch(key, fn -> 1 end, counting_compute_fn(agent, {"body", "etag"}))
    second = DotsCache.fetch(key, fn -> 1 end, counting_compute_fn(agent, {"different", "other-etag"}))

    assert first == {"body", "etag"}
    assert second == {"body", "etag"}
    assert Agent.get(agent, & &1) == 1
  end

  test "version change: compute_fn is called again and its new result is returned" do
    {:ok, agent} = Agent.start_link(fn -> 0 end)
    key = :dots_cache_test_version_change

    first = DotsCache.fetch(key, fn -> 1 end, counting_compute_fn(agent, {"body-v1", "etag-v1"}))
    second = DotsCache.fetch(key, fn -> 2 end, counting_compute_fn(agent, {"body-v2", "etag-v2"}))

    assert first == {"body-v1", "etag-v1"}
    assert second == {"body-v2", "etag-v2"}
    assert Agent.get(agent, & &1) == 2
  end

  test "caching disabled: compute_fn is called every time regardless of matching versions" do
    Application.put_env(:kristas_dogs, :dots_cache_enabled, false)

    {:ok, agent} = Agent.start_link(fn -> 0 end)
    key = :dots_cache_test_disabled

    first = DotsCache.fetch(key, fn -> 1 end, counting_compute_fn(agent, {"body", "etag"}))
    second = DotsCache.fetch(key, fn -> 1 end, counting_compute_fn(agent, {"body", "etag"}))

    assert first == {"body", "etag"}
    assert second == {"body", "etag"}
    assert Agent.get(agent, & &1) == 2
  end
end
