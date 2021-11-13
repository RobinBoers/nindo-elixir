defmodule Nindo.Application do
  @moduledoc false

  use Application
  import Nindo.Feeds, only: [cache_feed: 0]

  @opts [
    name: Nindo.Supervisor,
    strategy: :one_for_one,
  ]

  @children [
    Task.child_spec(&cache_feed/0),
  ]

  def start(_type, _args) do
    DynamicSupervisor.start_link(@opts)
    Supervisor.start_link(@children, strategy: :one_for_one)
  end

end