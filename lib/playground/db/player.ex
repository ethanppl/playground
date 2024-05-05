defmodule Playground.DB.Player do
  @moduledoc """
  Represents the players table
  """
  use Playground.DB.Schema

  typed_schema "players" do
    field :name, :string

    belongs_to :room, Playground.DB.Room

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(player, attrs) do
    player
    |> cast(attrs, [:name, :room_id])
    |> validate_required([:name, :room_id])
  end
end
