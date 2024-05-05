defmodule Playground.Factory do
  @moduledoc """
  Factories for creating test data.
  """

  use ExMachina.Ecto, repo: Playground.Repo

  use Playground.Factories.Player
  use Playground.Factories.Room
end
