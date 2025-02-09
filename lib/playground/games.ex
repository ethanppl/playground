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
  @spec list_games() :: [GameType.t()]
  def list_games do
    @games
    |> Map.keys()
    |> Enum.map(fn game_id -> get_game_details(game_id) end)
  end

  @doc """
  Return the details of a game
  """
  @callback get_game_details() :: GameType.t()

  @doc """
  Return the name of a game
  """
  @callback get_name() :: String.t()

  @doc """
  Return the minimum number of players for a game
  """
  @callback get_min_players() :: integer

  @doc """
  Return the maximum number of players for a game
  """
  @callback get_max_players() :: integer

  @doc """
  Create a game changeset for the game with the initial state of the game
  """
  @callback create_game_changeset(room :: Room.t()) :: Ecto.Changeset.t()

  @doc """
  Apply a move to a game, alter the game state and return the new state
  """
  @callback move(move :: map) :: map()

  defp game_module(game_id), do: @games[game_id]

  @doc """
  Return the changeset for creating a game

  ## Examples

      iex> create_game_changeset(%Room{}, "game_id")
      %Ecto.Changeset{}
  """
  @spec create_game_changeset(Room.t(), String.t()) :: Ecto.Changeset.t()
  def create_game_changeset(%Room{} = room, game_id) do
    game_module(game_id).create_game_changeset(room)
  end

  @doc """
  Return the game details

  ## Examples

      iex> get_game_details("game_id")
      %Playground.DB.GameType{}
  """
  @spec get_game_details(String.t()) :: GameType.t()
  def get_game_details(game_id) do
    game_module(game_id).get_game_details()
  end

  @doc """
  Return the game name

  ## Examples

      iex> get_name("game_id")
      "Tic Tac Toe"
  """
  @spec get_name(String.t()) :: String.t()
  def get_name(game_id) do
    game_module(game_id).get_name()
  end

  @doc """
  Apply a move to a game

  ## Examples

      iex> move(%{game: game, player_id: _player_id, move: _move, support: _support})
      %Playground.DB.Game{}
  """
  @spec move(%{
          game: Game.t(),
          player_id: integer | String.t(),
          move: map(),
          support: map()
        }) :: {:ok, Game.t()}
  def move(
        %{
          game: game,
          player_id: _player_id,
          move: _move,
          support: _support
        } = attr
      ) do
    new_state = game_module(game.type).move(attr)

    Game.update(game, %{state: new_state})
  end

  @doc """
  Given a list of players and a player_id, return the player's name.
  The player_id can be an integer or a string.

  ## Examples

      iex> get_player_name([%Playground.DB.Player{id: 1, name: "Alice"}, %Playground.DB.Player{id: 2, name: "Bob"}], 1)
      "Alice"
  """
  @spec get_player_name([Playground.DB.Player.t()], integer | String.t()) :: String.t()
  def get_player_name(players, player_id) do
    players |> Enum.find(&("#{&1.id}" == "#{player_id}")) |> Map.get(:name, "")
  end
end
