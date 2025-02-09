defmodule Playground.DB.Player do
  @moduledoc """
  Represents the players table
  """
  use Playground.DB.Schema

  alias Ecto.Query
  alias Playground.Repo

  require Ecto.Query

  typed_schema "players" do
    field :name, :string

    belongs_to :room, Playground.DB.Room

    timestamps(type: :utc_datetime)
  end

  @doc "Creates a new player"
  @spec changeset(Playground.DB.Player.t(), map) :: Ecto.Changeset.t()
  def changeset(player, attrs) do
    player
    |> cast(attrs, [:name, :room_id])
    |> validate_required([:name, :room_id])
  end

  @doc "Get a player by the given id"
  @spec get_player_by_id(integer) :: Playground.DB.Player.t() | nil
  def get_player_by_id(id) do
    Repo.one(Query.from(p in __MODULE__, where: p.id == ^id))
  end
end
