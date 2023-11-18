run:
	iex -S mix phx.server

# Setup https://fly.io/docs/elixir/the-basics/iex-into-running-app/
console:
	 flyctl ssh console --pty -C "/app/bin/kristas_dogs remote"
