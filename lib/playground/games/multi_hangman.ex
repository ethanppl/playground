defmodule Playground.Games.MultiHangman do
  @moduledoc """
  A module for a multiplayer hangman game
  """

  @behaviour Playground.Games

  @game_id "multi-hangman"
  @name "Multi Hangman"
  @min_players 2
  @max_players 4

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

    # A map of all players to their selected word, which is nil for now
    players_word_map = generate_player_map(players, nil)

    # A map of initialized word guesses map for all players
    guess_map_temp =
      generate_player_map(players, %{"guessed_correctly" => false, "history" => []})

    # A map of player_id to all other players
    word_guesses =
      Enum.reduce(players, %{}, fn player_id, acc ->
        Map.put(acc, player_id, Map.delete(guess_map_temp, player_id))
      end)

    state = %{
      "phase" => "select-words",
      "words" => players_word_map,
      "letter_guesses" => %{},
      "players_letter_guesses" => [],
      "word_guesses" => word_guesses,
      "players_order" => players,
      "turn" => nil,
      "winners" => []
    }

    Game.create_changeset(%Game{}, %{room_id: room.id, type: "multi-hangman", state: state})
  end

  defp generate_player_map(players, value) do
    Enum.reduce(players, %{}, fn player_id, acc ->
      Map.put(acc, player_id, value)
    end)
  end

  @doc """
  Make a move in the game
  """
  @impl Playground.Games
  def move(%{
        game: %{state: %{"phase" => "select-words"} = state},
        player_id: player_id,
        move: move
      }) do
    words = Map.put(state["words"], "#{player_id}", move)

    all_players_selected_word = Enum.all?(Map.values(words), &(&1 != nil))

    if all_players_selected_word do
      state
      |> Map.put("words", words)
      |> Map.put("phase", "guess-letters")
      |> Map.put("turn", Enum.at(state["players_order"], 0))
    else
      Map.put(state, "words", words)
    end
  end

  def move(%{
        game: %{state: %{"phase" => "guess-letters"} = state},
        player_id: player_id,
        move: %{
          "type" => "letter",
          "letter" => letter
        }
      }) do
    letter_guesses = Map.put(state["letter_guesses"], letter, player_id)

    state
    |> Map.put("letter_guesses", letter_guesses)
    |> update_players_letter_guesses_map(player_id, letter)
    |> set_next_player(player_id)
  end

  def move(%{
        game: %{state: %{"phase" => "guess-letters"} = state},
        player_id: player_id,
        move: %{
          "type" => "word",
          "target_player_id" => target_player_id,
          "word" => word
        },
        support: support
      }) do
    is_correct = state["words"][target_player_id] == word
    string_player_id = "#{player_id}"

    guess_history = [word | state["word_guesses"][string_player_id][target_player_id]["history"]]

    player_word_guesses_for_target = %{
      "guessed_correctly" => is_correct,
      "history" => guess_history
    }

    player_word_guesses =
      Map.put(
        state["word_guesses"][string_player_id],
        target_player_id,
        player_word_guesses_for_target
      )

    word_guesses = Map.put(state["word_guesses"], string_player_id, player_word_guesses)

    notify_word_guess_result(%{
      is_correct: is_correct,
      target_player_id: target_player_id,
      player_id: player_id,
      support: support
    })

    state
    |> Map.put("word_guesses", word_guesses)
    |> maybe_update_winners(player_id)
    |> maybe_update_next_player_after_word_guess(player_id)
  end

  def player_won?(state, player_id) do
    string_player_id = "#{player_id}"

    state["word_guesses"][string_player_id]
    |> Map.values()
    |> Enum.all?(& &1["guessed_correctly"])
  end

  defp notify_word_guess_result(%{
         is_correct: is_correct,
         target_player_id: target_player_id,
         player_id: player_id,
         support: %{
           send_notification_fn: send_notification_fn,
           players: players
         }
       }) do
    if is_correct do
      guesser_name = Games.get_player_name(players, player_id)
      target_name = Games.get_player_name(players, target_player_id)

      send_notification_fn.(%{
        receiver: %{type: :broadcast_except, except: [player_id, target_player_id]},
        message: "#{guesser_name} guessed #{target_name}'s word!",
        type: :notif
      })

      send_notification_fn.(%{
        receiver: %{type: :player, player: target_player_id},
        message: "#{guesser_name} guessed your word!",
        type: :notif
      })

      send_notification_fn.(%{
        receiver: %{type: :player, player: player_id},
        message: "Correct!",
        type: :info_plain
      })
    else
      send_notification_fn.(%{
        receiver: %{type: :player, player: player_id},
        message: "Oops! Incorrect!",
        type: :error_plain
      })
    end
  end

  defp maybe_update_winners(state, player_id) do
    if player_won?(state, player_id) do
      Map.put(state, "winners", [player_id | state["winners"]])
    else
      state
    end
  end

  defp maybe_update_next_player_after_word_guess(state, player_id) do
    if player_won?(state, player_id) do
      set_next_player(state, player_id)
    else
      state
    end
  end

  defp set_next_player(state, player_id) do
    if Enum.count(state["winners"]) == Enum.count(state["players_order"]) do
      # All players have won
      state
    else
      players_order = state["players_order"]
      current_player_index = Enum.find_index(players_order, &(&1 == player_id))

      next_player_index = rem(current_player_index + 1, Enum.count(players_order))
      next_player = Enum.at(players_order, next_player_index)

      if next_player in state["winners"] do
        # Skip the player if they have already won
        set_next_player(state, next_player)
      else
        Map.put(state, "turn", next_player)
      end
    end
  end

  defp update_players_letter_guesses_map(state, player_id, letter) do
    is_correct = letter_exists?(state["words"], letter)

    player_letter_guesses =
      %{"is_correct" => is_correct, "letter" => letter, "player" => player_id}

    updated_players_letter_guesses = [player_letter_guesses | state["players_letter_guesses"]]

    Map.put(state, "players_letter_guesses", updated_players_letter_guesses)
  end

  defp letter_exists?(words, letter) do
    words
    |> Map.values()
    |> Enum.any?(fn word -> String.contains?(word, letter) end)
  end
end
