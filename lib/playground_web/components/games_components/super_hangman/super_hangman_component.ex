defmodule PlaygroundWeb.GamesComponents.SuperHangmanComponent do
  @moduledoc """
  A component for a multiplayer hangman game
  """

  use PlaygroundWeb, :live_component

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <%= case @game.state["phase"] do %>
        <% "select-words" -> %>
          <.live_component
            id={:multi_hangman_select_word}
            module={PlaygroundWeb.GamesComponents.SuperHangmanComponent.SelectWord}
            game={@game}
            player_id={@player_id}
          />
        <% "guess-letters" -> %>
          <.live_component
            id={:multi_hangman_guess_letters}
            module={PlaygroundWeb.GamesComponents.SuperHangmanComponent.GuessLetters}
            game={@game}
            players={@players}
            player_id={@player_id}
          />
      <% end %>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end
end
