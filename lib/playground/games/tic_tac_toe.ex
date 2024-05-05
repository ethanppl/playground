defmodule Playground.Games.TicTacToe do
  @moduledoc """
  A module for the Tic Tac Toe game
  """

  @behaviour Playground.Games

  @game_id "tic-tac-toe"
  @name "Tic Tac Toe"
  @min_players 2
  @max_players 2

  alias Playground.DB.{Game, GameType, Room}

  @impl Playground.Games
  def get_name(), do: @name

  @impl Playground.Games
  def get_min_players(), do: @min_players

  @impl Playground.Games
  def get_max_players(), do: @max_players

  @impl Playground.Games
  def get_game_details() do
    %GameType{
      game_id: @game_id,
      name: @name,
      min_players: @min_players,
      max_players: @max_players
    }
  end

  @doc """
  Create a game changeset for Tic Tac Toe
  """
  @impl Playground.Games
  def create_game_changeset(%Room{} = room) do
    players = room.players |> Enum.map(& &1.id) |> Enum.shuffle()

    state = %{
      "players" => %{
        "#{Enum.at(players, 0)}" => "x",
        "#{Enum.at(players, 1)}" => "o"
      },
      "symbols" => %{
        "x" => "#{Enum.at(players, 0)}",
        "o" => "#{Enum.at(players, 1)}"
      },
      "board" => [
        [nil, nil, nil],
        [nil, nil, nil],
        [nil, nil, nil]
      ],
      "turn" => "#{Enum.at(players, 0)}",
      "winner" => nil
    }

    Game.create_changeset(%Game{}, %{room_id: room.id, type: "tic-tac-toe", state: state})
  end

  @doc """
  Make a move in the game
  """
  @impl Playground.Games
  def move(%{game: game, player_id: player_id, move: move}) do
    state = game.state
    player_symbol = state["players"]["#{player_id}"]
    another_player = state["players"] |> Map.keys() |> Enum.find(&(&1 != "#{player_id}"))

    cond do
      state["turn"] != "#{player_id}" ->
        game

      get_cell(state["board"], move.row, move.col) != nil ->
        game

      true ->
        new_row = List.replace_at(Enum.at(state["board"], move.row), move.col, player_symbol)
        new_board = List.replace_at(state["board"], move.row, new_row)

        state
        |> Map.put("board", new_board)
        |> Map.put("turn", another_player)
        |> maybe_set_winner()
    end
  end

  defp get_cell(board, row, column) do
    board |> Enum.at(row) |> Enum.at(column)
  end

  defp maybe_set_winner(state) do
    board = state["board"]

    eight_ways_of_winning = [
      {{0, 0}, {0, 1}, {0, 2}},
      {{1, 0}, {1, 1}, {1, 2}},
      {{2, 0}, {2, 1}, {2, 2}},
      {{0, 0}, {1, 0}, {2, 0}},
      {{0, 1}, {1, 1}, {2, 1}},
      {{0, 2}, {1, 2}, {2, 2}},
      {{0, 0}, {1, 1}, {2, 2}},
      {{0, 2}, {1, 1}, {2, 0}}
    ]

    winning_way =
      Enum.find(eight_ways_of_winning, fn {{ar, ac}, {br, bc}, {cr, cc}} ->
        get_cell(board, ar, ac) == get_cell(board, br, bc) and
          get_cell(board, br, bc) == get_cell(board, cr, cc) and
          get_cell(board, ar, ac) != nil
      end)

    case winning_way do
      nil ->
        maybe_draw(state)

      {{row, col}, _cell, _cell2} ->
        winning_symbol = get_cell(board, row, col)
        Map.put(state, "winner", state["symbols"][winning_symbol])
    end
  end

  defp maybe_draw(state) do
    board = state["board"]

    if Enum.all?(board, fn row -> Enum.all?(row, fn cell -> cell != nil end) end) do
      Map.put(state, "winner", "draw")
    else
      state
    end
  end
end
