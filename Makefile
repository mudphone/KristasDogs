run:
	iex -S mix phx.server

# Setup https://fly.io/docs/elixir/the-basics/iex-into-running-app/
console:
	flyctl ssh console --pty -C "/app/bin/kristas_dogs remote"

deploy:
	flyctl deploy

# In case the builder will not connect.
# Kill the following process:
#   /usr/local/bin/fly agent run /Users/username/.fly/agent-logs/4102937902.log
fly-restart:
	flyctl agent restart
