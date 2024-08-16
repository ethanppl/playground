defmodule Playground.Games.SuperTicTacToe do
  @moduledoc """
  A module for the Super Tic Tac Toe game
  """

  @behaviour Playground.Games

  @game_id "super-tic-tac-toe"
  @name "Super Tic Tac Toe"
  @min_players 2
  @max_players 2
  @eight_ways_of_winning [
    {{0, 0}, {0, 1}, {0, 2}},
    {{1, 0}, {1, 1}, {1, 2}},
    {{2, 0}, {2, 1}, {2, 2}},
    {{0, 0}, {1, 0}, {2, 0}},
    {{0, 1}, {1, 1}, {2, 1}},
    {{0, 2}, {1, 2}, {2, 2}},
    {{0, 0}, {1, 1}, {2, 2}},
    {{0, 2}, {1, 1}, {2, 0}}
  ]

  alias Playground.DB.{Game, GameType, Room}
  alias Playground.Games

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

    empty_three_by_three = [
      [nil, nil, nil],
      [nil, nil, nil],
      [nil, nil, nil]
    ]

    boards =
      Enum.reduce(0..9, %{}, fn index, acc ->
        Map.put(acc, "#{index}", empty_three_by_three)
      end)

    state = %{
      "players" => %{
        "#{Enum.at(players, 0)}" => "x",
        "#{Enum.at(players, 1)}" => "o"
      },
      "symbols" => %{
        "x" => "#{Enum.at(players, 0)}",
        "o" => "#{Enum.at(players, 1)}"
      },
      "boards" => boards,
      "next_board" => "9",
      "turn" => "#{Enum.at(players, 0)}",
      "winner" => nil
    }

    Game.create_changeset(%Game{}, %{room_id: room.id, type: @game_id, state: state})
  end

  @doc """
  Make a move in the game
  """
  @impl Playground.Games
  def move(%{
        game: game,
        player_id: player_id,
        move: move,
        support: support
      }) do
    state = game.state
    player_symbol = state["players"]["#{player_id}"]
    another_player = state["players"] |> Map.keys() |> Enum.find(&(&1 != "#{player_id}"))

    cond do
      # Not the player turn
      state["turn"] != "#{player_id}" ->
        state

      # Cannot directly make a move on board 9
      move.board_id == "9" ->
        state

      # The cell is not empty
      get_cell(state["boards"], move.board_id, move.row, move.col) != nil ->
        state

      true ->
        new_boards = set_cell(state["boards"], move.board_id, move.row, move.col, player_symbol)

        state
        |> Map.put("boards", new_boards)
        |> Map.put("turn", another_player)
        |> maybe_set_winner(move.board_id)
        |> set_next_board(move.row, move.col)
        |> maybe_send_notification(support)
    end
  end

  defp set_cell(boards, board_id, row, col, value) do
    new_row =
      boards
      |> Map.get(board_id)
      |> Enum.at(row)
      |> List.replace_at(col, value)

    new_board =
      boards
      |> Map.get(board_id)
      |> List.replace_at(row, new_row)

    Map.put(boards, board_id, new_board)
  end

  defp get_cell(boards, board_id, row, column) do
    boards |> Map.get(board_id) |> Enum.at(row) |> Enum.at(column)
  end

  defp get_cell(board, row, column) do
    board |> Enum.at(row) |> Enum.at(column)
  end

  defp set_next_board(state, row, col) do
    board_num = row * 3 + col
    board_is_full = board_is_full?(state["boards"]["#{board_num}"])
    board_is_won = get_cell(state["boards"], "9", row, col) != nil

    next_board_num =
      if board_is_full or board_is_won do
        "9"
      else
        "#{board_num}"
      end

    Map.put(state, "next_board", next_board_num)
  end

  defp maybe_set_winner(state, board_id) do
    board = Map.get(state["boards"], board_id)

    winning_way =
      Enum.find(@eight_ways_of_winning, fn {{ar, ac}, {br, bc}, {cr, cc}} ->
        get_cell(board, ar, ac) == get_cell(board, br, bc) and
          get_cell(board, br, bc) == get_cell(board, cr, cc) and
          get_cell(board, ar, ac) != nil
      end)

    case {winning_way, board_id} do
      {nil, _board_id} ->
        maybe_draw(state)

      {{{row, col}, _cell, _cell2}, "9"} ->
        winning_symbol = get_cell(board, row, col)
        Map.put(state, "winner", state["symbols"][winning_symbol])

      {{{row, col}, _cell, _cell2}, board_id} ->
        winning_symbol = get_cell(board, row, col)
        {row, col} = get_row_col_from_board_id(board_id)

        new_boards = set_cell(state["boards"], "9", row, col, winning_symbol)
        new_state = Map.put(state, "boards", new_boards)

        maybe_set_winner(new_state, "9")
    end
  end

  defp maybe_draw(state) do
    all_board_is_full_or_won =
      Enum.all?(0..9, fn board_num ->
        board_is_full?(state["boards"]["#{board_num}"]) or
          state["boards"]["9"] |> Enum.at(floor(board_num / 3)) |> Enum.at(rem(board_num, 3)) !=
            nil
      end)

    if all_board_is_full_or_won do
      Map.put(state, "winner", "draw")
    else
      state
    end
  end

  def board_is_full?(board) do
    Enum.all?(board, fn row -> row_is_full?(row) end)
  end

  defp row_is_full?(row) do
    Enum.all?(row, fn cell -> cell != nil end)
  end

  defp get_row_col_from_board_id(board_id) do
    board_num = String.to_integer(board_id)
    row = floor(board_num / 3)
    col = rem(board_num, 3)

    {row, col}
  end

  defp maybe_send_notification(state, %{
         send_notification_fn: send_notification_fn,
         players: players
       }) do
    case state do
      %{"winner" => "draw"} ->
        send_notification_fn.(%{
          receiver: %{type: :broadcast},
          message: "It's a draw!",
          type: :notif
        })

      %{"winner" => winner} when not is_nil(winner) ->
        winner_name = Games.get_player_name(players, winner)

        send_notification_fn.(%{
          receiver: %{type: :broadcast_except, except: [winner]},
          message: "#{winner_name} won!",
          type: :error_plain
        })

        send_notification_fn.(%{
          receiver: %{type: :player, player: winner},
          message: "You won!",
          type: :info_plain
        })

      %{"turn" => another_player} ->
        send_notification_fn.(%{
          receiver: %{type: :player, player: another_player},
          message: "Your Turn!",
          type: :notif
        })

      _other ->
        nil
    end

    state
  end
end
