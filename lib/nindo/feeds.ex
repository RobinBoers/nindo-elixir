defmodule Nindo.Feeds do
  @moduledoc false

  alias Nindo.{Accounts, FeedAgent}
  alias NinDB.{Database, Account}

  def add(feed, user) do
    feeds = user.feeds
    if feed not in feeds do
      Accounts.change(:feeds, [feed | feeds], user)
    end
    update_agent(user)
  end

  def remove(feed, user) do
    feed = empty_to_nil(feed)
    feeds = user.feeds
    if feed in feeds do
      Accounts.change(:feeds, feeds -- [feed], user)
    end
    update_agent(user)
  end

  def follow(person, user) do
    following = user.following
    if person not in following do
      Accounts.change(:following, [person | following], user)
    end
    update_agent(user)
  end

  def unfollow(person, user) do
    following = user.following
    if person in following do
      Accounts.change(:following, following -- [person], user)
    end
    update_agent(user)
  end

  # Caching feeds

  def cache_feed() do
    # Start lookup table for user feeds
    DynamicSupervisor.start_child(
        Nindo.Supervisor,
        FeedAgent.child_spec()
    )

    Database.list(Account)
    |> Enum.map(fn user -> Task.async(fn ->
      cache(user)
    end) end)
    |> Task.await_many()
  end

  def cache(user) do
    username = user.username
    feeds = user.feeds

    if feeds != nil do
      {:ok, pid} =
        DynamicSupervisor.start_child(
          Nindo.Supervisor,
          FeedAgent.child_spec(username)
        )

        FeedAgent.add_user(username, pid)
        FeedAgent.update(pid)
    end
  end

  # Private methods

  defp empty_to_nil(map) do
    map
    |> Enum.map(fn
      {key, val} when val === "" -> {key, nil}
      {key, val} -> {key, val}
    end)
    |> Enum.into(%{})
  end

  defp update_agent(user) do
    Task.async(fn ->
      user
      |> FeedAgent.get_pid()
      |> FeedAgent.update()
    end)
  end

end
