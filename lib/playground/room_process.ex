defmodule Playground.RoomProcess do
  @moduledoc """
  The RoomProcess module host a process for managing a room
  """

  use GenServer

  alias Playground.{Games, Rooms}

  def start_link(room) do
    case GenServer.start_link(__MODULE__, room, name: via(room.code)) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end

  @doc """
  Join the room by the given room code, with the given player name.
  """
  def join_room(%{code: room_code, player_name: player_name}) do
    case whereis(room_code) do
      nil ->
        {:error, :room_not_found}

      _pid ->
        GenServer.call(via(room_code), {:join_room, player_name})
    end
  end

  @doc """
  Remove the given player from the room by room code.
  """
  def remove_player(%{code: room_code, player_id: player_id}) do
    case whereis(room_code) do
      nil ->
        {:error, :room_not_found}

      _pid ->
        GenServer.call(via(room_code), {:remove_player, player_id})
    end
  end

  @doc """
  Get the room details by the given room code.
  """
  def get_room_details(room_code) do
    case whereis(room_code) do
      nil ->
        {:error, :room_not_found}

      _pid ->
        GenServer.call(via(room_code), {:get_room_details})
    end
  end

  @doc """
  Start a game of the given game_id
  """
  def start_game(%{code: room_code, game_id: game_id}) do
    case whereis(room_code) do
      nil ->
        {:error, :room_not_found}

      _pid ->
        GenServer.call(via(room_code), {:start_game, game_id})
    end
  end

  @doc """
  End the current game in the room
  """
  def end_game(room_code) do
    case whereis(room_code) do
      nil ->
        {:error, :room_not_found}

      _pid ->
        GenServer.call(via(room_code), :end_game)
    end
  end

  @doc """
  A move in the game
  """
  def game_move(%{code: room_code, player_id: player_id, move: move}) do
    case whereis(room_code) do
      nil ->
        {:error, :room_not_found}

      _pid ->
        GenServer.call(
          via(room_code),
          {:game_move, %{player_id: player_id, move: move}}
        )
    end
  end

  @impl GenServer
  def init(room) do
    {:ok, room, {:continue, :broadcast}}
  end

  @impl GenServer
  def handle_continue(:broadcast, room) do
    Phoenix.PubSub.broadcast(Playground.PubSub, room.code, {:room_updated, room})

    {:noreply, room}
  end

  @impl GenServer
  def handle_call({:join_room, player_name}, _from, room) do
    {:ok, %{room: updated_room, player: _player}} =
      res = Rooms.join_room(%{code: room.code, player_name: player_name})

    {:reply, res, updated_room, {:continue, :broadcast}}
  end

  @impl GenServer
  def handle_call({:remove_player, player_id}, _from, room) do
    res = Rooms.remove_player(%{code: room.code, player_id: player_id})

    case res do
      {:ok, nil} ->
        {:stop, {:shutdown, "empty room"}, :ok, room}

      {:ok, updated_room} ->
        {:reply, res, updated_room, {:continue, :broadcast}}

      error ->
        {:reply, error, room}
    end
  end

  @impl GenServer
  def handle_call({:get_room_details}, _from, room) do
    {:reply, {:ok, room}, room}
  end

  @impl GenServer
  def handle_call({:start_game, game_id}, _from, room) do
    {:ok, updated_room} =
      res = Rooms.start_game(%{code: room.code, game_id: game_id})

    {:reply, res, updated_room, {:continue, :broadcast}}
  end

  @impl GenServer
  def handle_call(:end_game, _from, room) do
    {:ok, updated_room} = res = Rooms.end_game(room.code)

    {:reply, res, updated_room, {:continue, :broadcast}}
  end

  @impl GenServer
  def handle_call(
        {:game_move, %{player_id: player_id, move: move}},
        _from,
        room
      ) do
    send_notification_fn = fn %{receiver: _receiver, message: _message, type: _type} = payload ->
      Phoenix.PubSub.broadcast(
        Playground.PubSub,
        room.code,
        {:room_notification, Map.merge(%{sender: player_id}, payload)}
      )
    end

    Games.move(%{
      game: room.active_game,
      player_id: player_id,
      move: move,
      support: %{
        send_notification_fn: send_notification_fn,
        players: room.players
      }
    })

    {:ok, updated_room} = Rooms.get_room_details(room.code)

    {:reply, :ok, updated_room, {:continue, :broadcast}}
  end

  def whereis(room_code) do
    case Swarm.whereis_name({__MODULE__, room_code}) do
      :undefined -> nil
      pid -> pid
    end
  end

  defp via(room_code) do
    {:via, :swarm, {__MODULE__, room_code}}
  end
end
