defmodule PlaygroundWeb.GamesComponents.HowToPlay do
  @moduledoc """
  A component for a multiplayer hangman game
  """

  use PlaygroundWeb, :live_component

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="w-full text-center py-24 text-zinc-500">
      <.icon name="hero-wrench-screwdriver" class="h-4 w-4 pr-2" />
      <span>Working in Progress!</span>
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
