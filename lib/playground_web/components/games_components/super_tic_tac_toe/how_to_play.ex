defmodule PlaygroundWeb.GamesComponents.SuperTicTacToeComponent.HowToPlay do
  @moduledoc """
  A how to play component for super tic tac toe
  """

  use PlaygroundWeb, :live_component

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-4">
      <p>
        Have you ever played tic-tac-toe before? This is the same, but with 9
        small grids and 1 large grid.
      </p>

      <p>
        Each move in a small grid limits which small grid the opponent's next
        move is in, indicated by the relative location of the move. If the small
        grid is not available, the next move is not limited. Winning the small
        grid will win the corresponding cell in the large grid. The goal is to
        win the large grid.
      </p>

      <p>
        Or just try it once and you will understand!
      </p>

      <div class="p-2">
        <picture>
          <source type="image/webp" srcset="/images/games/super-tic-tac-toe/rule.webp" />
          <img src="/images/games/super-tic-tac-toe/rule.png" class="w-11/12 mx-auto" />
        </picture>
        <div class="w-full text-center text-sm text-zinc-400">
          Because opponent played in the top right corner, you must play in the top right small grid
        </div>
      </div>

      <p>
        You may
        <a
          href="https://en.wikipedia.org/wiki/Ultimate_tic-tac-toe"
          class="underline text-blue-500"
          target="_blank"
        >
          read more about the game on Wikipedia too
        </a>
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
