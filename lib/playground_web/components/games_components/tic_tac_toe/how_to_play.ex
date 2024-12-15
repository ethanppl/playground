defmodule PlaygroundWeb.GamesComponents.TicTacToeComponent.HowToPlay do
  @moduledoc """
  A how to play component for tic tac toe
  """

  use PlaygroundWeb, :live_component

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-4 text-center">
      <p>
        Well, it's <a
          href="https://en.wikipedia.org/wiki/Tic-tac-toe"
          class="underline text-blue-500"
          target="_blank"
        >tic-tac-toe</a>!
      </p>
      <div class="p-2">
        <picture>
          <source type="image/webp" srcset="/images/games/tic-tac-toe.webp" />
          <img src="/images/games/tic-tac-toe.png" class="w-11/12 mx-auto" />
        </picture>
      </div>
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
