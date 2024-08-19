defmodule PlaygroundWeb.ListGamesLive do
  use PlaygroundWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    games = Playground.Games.list_games()

    {:noreply,
     socket
     |> assign(:games, games)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :list, _params) do
    socket
    |> assign(:page_title, "List Games")
    |> assign(:room, nil)
  end

  defp apply_action(socket, :show, params) do
    IO.inspect(params)
    assign(socket, :page_title, "Game")
  end
end
