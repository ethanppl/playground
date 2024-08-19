defmodule Playground.Games do
  @moduledoc """
  A module for the games
  """

  alias Playground.DB.{Game, GameType, Room}
  alias Playground.Games.{SuperHangman, SuperTicTacToe, TicTacToe}

  require Ecto.Query

  @games %{
    "tic-tac-toe" => TicTacToe,
    "super-tic-tac-toe" => SuperTicTacToe,
    "super-hangman" => SuperHangman
  }

  @doc """
  Lists all the games

  ## Examples

      iex> list_games()
      [%Playground.DB.GameType{}]
  """
  def list_games do
    @games
    |> Map.keys()
    |> Enum.map(fn game_id -> get_game_details(game_id) end)
  end

  @callback get_game_details() :: GameType.t()
  @callback get_name() :: String.t()
  @callback get_min_players() :: integer
  @callback get_max_players() :: integer
  @callback create_game_changeset(room :: Room.t()) :: Ecto.Changeset.t()
  @callback move(move :: map) :: map()

  defp game_module(game_id), do: @games[game_id]

  @doc """
  Return the changeset for creating a game

  ## Examples

      iex> create_game_changeset(%Room{}, "game_id")
      %Ecto.Changeset{}
  """
  def create_game_changeset(%Room{} = room, game_id) do
    module = game_module(game_id)

    apply(module, :create_game_changeset, [room])
  end

  @doc """
  Return the game details

  ## Examples

      iex> get_game_details("game_id")
      %Playground.DB.GameType{}
  """
  def get_game_details(game_id) do
    module = game_module(game_id)

    apply(module, :get_game_details, [])
  end

  @doc """
  Return the game name

  ## Examples

      iex> get_name("game_id")
      "Tic Tac Toe"
  """
  def get_name(game_id) do
    module = game_module(game_id)

    apply(module, :get_name, [])
  end

  @doc """
  Apply a move to a game

  ## Examples

      iex> move(%{game: game, player_id: _player_id, move: _move, support: _support})
      %Playground.DB.Game{}
  """
  def move(
        %{
          game: game,
          player_id: _player_id,
          move: _move,
          support: _support
        } = attr
      ) do
    module = game_module(game.type)

    new_state = apply(module, :move, [attr])

    Game.update(game, %{state: new_state})
  end

  @doc """
  Given a list of players and a player_id, return the player's name.
  The player_id can be an integer or a string.

  ## Examples

      iex> get_player_name([%Playground.DB.Player{id: 1, name: "Alice"}, %Playground.DB.Player{id: 2, name: "Bob"}], 1)
      "Alice"
  """
  def get_player_name(players, player_id) do
    players |> Enum.find(&("#{&1.id}" == "#{player_id}")) |> Map.get(:name, "")
  end
end
