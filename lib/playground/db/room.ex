defmodule Playground.DB.Room do
  @moduledoc """
  Represents the rooms table
  """
  use Playground.DB.Schema

  @primary_key {:id, :id, autogenerate: true}
  typed_schema "rooms" do
    field :code, :string
    field :status, Ecto.Enum, values: [:open, :playing, :killed], default: :open

    belongs_to :host, Playground.DB.Player
    has_many :players, Playground.DB.Player
    has_many :games, Playground.DB.Game
    has_one :active_game, Playground.DB.Game, where: [status: :active]

    timestamps(type: :utc_datetime)
  end

  @doc """
  Change set to create a room.
  Validate the code is 4 characters long.
  """
  def create_changeset(room, attrs) do
    room
    |> cast(attrs, [:code, :status])
    |> validate_required([:code, :status])
    |> validate_length(:code, is: 4)
  end

  @doc """
  Set the host of the room
  """
  def set_host_changeset(room, attrs) do
    room
    |> cast(attrs, [:host_id])
    |> validate_required([:host_id])
    |> foreign_key_constraint(:host_id)
  end

  @doc """
  Update the status of the room
  """
  def set_status_changeset(room, attrs) do
    room
    |> cast(attrs, [:status])
    |> validate_required([:status])
  end

  @doc """
  Returns a query on Playground.DB.Room, with :room as a named binding.
  """
  def base_query() do
    Query.from(r in __MODULE__, as: :room)
  end

  @doc """
  Returns a query on Playground.DB.Room, where the room has the given code.
  """
  def where_code(query, code) do
    Query.where(query, [room: r], r.code == ^code)
  end

  @doc """
  Returns a query on Playground.DB.Room, where the room is active.
  """
  def where_is_active(query) do
    Query.where(query, [room: r], r.status in [:open, :playing])
  end
end
