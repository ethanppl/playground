defmodule Playground.DB.Game do
  @moduledoc """
  Represents the games table
  """
  use Playground.DB.Schema

  typed_schema "games" do
    field :state, :map
    field :status, Ecto.Enum, values: [:active, :ended], default: :active
    field :type, :string

    belongs_to :room, Playground.DB.Room

    timestamps(type: :utc_datetime)
  end

  @doc "Creates a new game"
  @spec create_changeset(Playground.DB.Game.t(), map) :: Ecto.Changeset.t()
  def create_changeset(game, attrs) do
    game
    |> cast(attrs, [:state, :type, :room_id])
    |> cast(%{status: :active}, [:status])
    |> validate_required([:state, :status, :type, :room_id])
  end

  @doc "Updates a game status and/or state"
  @spec update(Playground.DB.Game.t(), map) :: {:ok, Playground.DB.Game.t()}
  def update(game, attr) do
    game
    |> cast(attr, [:status, :state])
    |> Playground.Repo.update()
  end
end
