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
    assign(socket, :page_title, "List Games")
  end

  defp apply_action(socket, :show, params) do
    game_id = params["game"]

    socket
    |> assign(:page_title, Playground.Games.get_name(game_id))
    |> assign(:game, Playground.Games.get_game_details(game_id))
  end
end
