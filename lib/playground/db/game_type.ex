defmodule Playground.DB.GameType do
  @moduledoc """
  Represents the game_types table
  """
  use Playground.DB.Schema

  typed_embedded_schema do
    field :game_id, :string
    field :name, :string
    field :min_players, :integer
    field :max_players, :integer
  end
end
