defmodule Playground.Rooms do
  @moduledoc """
  The Rooms context.
  """

  import Ecto.Query, warn: false

  @preload_keys [:host, :players, :active_game]

  alias Ecto.Multi
  alias Ecto.Query

  alias Playground.DB.{Game, Player, Room}
  alias Playground.Games
  alias Playground.Repo

  @doc """
  Creates a room.

  ## Examples

      iex> create_room(%{host_name: "name"})
      {:ok, %Playground.DB.Room{}}

  """
  def create_room(%{host_name: host_name}) do
    with {:ok, code} <- generate_code(),
         {:ok, %{update_room_host: room}} <-
           create_room_multi(%{host_name: String.upcase(host_name), code: code}) do
      {:ok, Repo.preload(room, @preload_keys)}
    end
  end

  defp create_room_multi(%{host_name: host_name, code: code}) do
    Multi.new()
    |> Multi.insert(:insert_room, Room.create_changeset(%Room{}, %{code: code}))
    |> Multi.insert(:insert_host, fn %{insert_room: room} ->
      Player.changeset(%Player{}, %{name: host_name, room_id: room.id})
    end)
    |> Multi.update(:update_room_host, fn %{insert_room: room, insert_host: %{id: host_id}} ->
      Room.set_host_changeset(room, %{host_id: host_id})
    end)
    |> Repo.transaction()
  end

  @doc """
  Generates a unique code for a room.
  The code is a 4 character string.

  ## Examples

      iex> generate_code()
      {:ok, "ABCD"}
  """
  def generate_code do
    generate_code(0)
  end

  defp generate_code(count) when count < 5 do
    code = do_generate_code()

    check_code =
      Room.base_query()
      |> Room.where_code(code)
      |> Room.where_is_active()
      |> Repo.all()

    case check_code do
      [] -> {:ok, code}
      _ -> generate_code(count + 1)
    end
  end

  defp generate_code(count) do
    {:error, "Failed to generate a unique code after #{count} attempts"}
  end

  defp do_generate_code do
    range = ?A..?Z

    1..4
    |> Enum.map(fn _i -> Enum.random(range) end)
    |> List.to_string()
  end

  @doc """
  Create a player and joins a room by code.

  ## Examples

      iex> join_room(%{code: "ABCD", player_name: "name"})
      {:ok, %{room: %Playground.DB.Room{}, player: %Playground.DB.Player{}}

  """
  def join_room(%{code: code, player_name: player_name}) do
    with {:ok, room} <- get_room_details(code),
         {:ok, player} <- create_player(room, String.upcase(player_name)),
         {:ok, updated_room_details} <- get_room_details(code) do
      {:ok, %{room: updated_room_details, player: player}}
    end
  end

  defp create_player(room, player_name) do
    %Player{}
    |> Player.changeset(%{name: player_name, room_id: room.id})
    |> Repo.insert()
  end

  @doc """
  Start a game in a room.

  ## Examples

      iex> start_game(%{code: "ABCD", game_id: "game_id"})
      {:ok, %Playground.DB.Room{}}
  """
  def start_game(%{code: code, game_id: game_id}) do
    with {:ok, room} <- get_room_details(code),
         false <- has_active_game?(room),
         {:ok, _multi} <- start_game_multi(%{room: room, game_id: game_id}) do
      get_room_details(code)
    else
      true -> {:error, :cannot_start_game}
      error -> error
    end
  end

  @spec has_active_game?(room :: Room.t()) :: boolean
  defp has_active_game?(room) do
    room
    |> Repo.preload([:games])
    |> case do
      %Room{games: games} ->
        Enum.any?(games, fn game -> game.status == :active end)

      _ ->
        false
    end
  end

  defp start_game_multi(%{room: room, game_id: game_id}) do
    Multi.new()
    |> Multi.insert(:insert_game, Games.create_game_changeset(room, game_id))
    |> Multi.update(:update_room_status, fn _map ->
      Room.set_status_changeset(room, %{status: :playing})
    end)
    |> Repo.transaction()
  end

  @doc """
  End the current game in the room

  ## Examples

      iex> end_game("ABCD")
      {:ok, %Playground.DB.Room{}}
  """
  def end_game(code) do
    with {:ok, room} <- get_room_details(code),
         true <- has_active_game?(room),
         {:ok, _multi} <- Game.update(room.active_game, %{status: :ended}) do
      get_room_details(code)
    else
      false -> {:error, :cannot_end_game}
      error -> error
    end
  end

  @doc """
  Get the details of a room by code.
  The room has to be active

  ## Examples

      iex> get_room_details(%{code: "ABCD"})
      {:ok, %Playground.DB.Room{}}

  """
  def get_room_details(room_code) do
    do_get_room =
      Room.base_query()
      |> Room.where_code(room_code)
      |> Room.where_is_active()
      |> Query.preload(^@preload_keys)
      |> Repo.one()

    case do_get_room do
      nil -> {:error, :room_not_found}
      room -> {:ok, room}
    end
  end

  @doc """
  Remove a player from a room by code.

  ## Examples

      iex> remove_player(%{code: "ABCD", player_id: 34})
      {:ok, %Playground.DB.Room{}}

  """
  def remove_player(%{code: code, player_id: player_id})
      when is_binary(code) and is_number(player_id) do
    with {:ok, room} <- validate_room_exist(code),
         :ok <- validate_player_is_in_room(room, player_id),
         {:ok, _multi} <- remove_player_multi(room, player_id),
         {:ok, updated_room_details} <- get_room_details(code) do
      {:ok, updated_room_details}
    else
      # The room is deleted because the host is removed and there is no more players
      {:error, :room_not_found} ->
        {:ok, nil}

      error ->
        error
    end
  end

  defp validate_room_exist(code) do
    case get_room_details(code) do
      {:error, :room_not_found} ->
        {:error, "Room #{code} does not exist"}

      res ->
        res
    end
  end

  defp validate_player_is_in_room(%Room{players: players, code: code}, player_id) do
    do_find_player =
      Enum.find(players, fn player ->
        player.id == player_id
      end)

    case do_find_player do
      nil ->
        {:error, "Player #{player_id} is not part of room #{code}"}

      %Player{} ->
        :ok
    end
  end

  # Reassign host when the given player id is the host
  # Then delete the user
  defp remove_player_multi(%Room{} = room, player_id) do
    Multi.new()
    |> reassign_host(room, player_id)
    |> delete_player(player_id)
    |> Repo.transaction()
  end

  defp reassign_host(
         %Multi{} = multi,
         %Room{host: %Player{id: host_id}} = room,
         host_id
       ) do
    case find_new_host(room) do
      nil ->
        multi

      %Player{id: new_host_id} ->
        Multi.update(multi, :update_host, Room.set_host_changeset(room, %{host_id: new_host_id}))
    end
  end

  defp reassign_host(%Multi{} = multi, _room, _player_id) do
    multi
  end

  defp find_new_host(%Room{host: %Player{id: host_id}, players: players}) do
    Enum.find(players, fn player ->
      player.id != host_id
    end)
  end

  defp delete_player(%Multi{} = multi, player_id) do
    Multi.delete(multi, :delete_player, %Player{id: player_id})
  end
end
