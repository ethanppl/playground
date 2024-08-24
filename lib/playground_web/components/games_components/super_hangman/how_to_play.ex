defmodule PlaygroundWeb.GamesComponents.SuperHangmanComponent.HowToPlay do
  @moduledoc """
  A how to play component for super hangman
  """

  use PlaygroundWeb, :live_component

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-4">
      <p>
        Have you ever played Hangman before? There is a secret word and you take
        turns guessing a letter. If the word contains the letter, the position
        of the letter is shown. If not, you lose a point.
      </p>

      <div class="p-2">
        <img src="/images/games/super-hangman/hangman.png" class="w-11/12 mx-auto p-2" />
        <div class="w-full text-center text-sm text-zinc-400">
          'E', 'O', 'S' and 'T' are incorrect
        </div>
      </div>

      <p>
        This game is very similar, but you are both the questioner and the
        guesser. Each player has a secret word that the others are trying to
        guess. Every time you guess a letter, you are guessing for all the
        words. And if the letter you guessed is present in your secret word, it
        will also be revealed. So, be careful!
      </p>

      <div class="p-2">
        <img src="/images/games/super-hangman.png" class="w-11/12 mx-auto" />
        <div class="w-full text-center text-sm text-zinc-400">
          The viewer is Kevin. His word is 'YELLOW', he is trying to guess Bob's
          word, and he has guessed Staurt's word.
        </div>
      </div>

      <p>
        Everyone takes turns guessing letters, but everyone can guess any of the
        others' secret words at any time. Your goal is to guess all the secret
        words faster than anyone else! Good luck!
      </p>
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
