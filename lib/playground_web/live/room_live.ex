defmodule PlaygroundWeb.RoomLive do
  use PlaygroundWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Playground.PubSub, session["room_code"])
    end

    {:ok,
     socket
     |> assign(:code_from_session, session["room_code"])
     |> assign(:player_id, session["user_id"])
     |> assign(:player_name, session["user_name"])}
  end

  @impl Phoenix.LiveView
  def handle_params(
        %{"code" => code} = params,
        _url,
        # The code in the URL has to match the code in the session
        %{assigns: %{code_from_session: code}} = socket
      ) do
    case Playground.RoomProcess.get_room_details(code) do
      {:error, :room_not_found} ->
        {:noreply, push_navigate(socket, to: "/", replace: true)}

      {:ok, room_details} ->
        is_host = room_details.host_id === socket.assigns.player_id

        games = Playground.Games.list_games()

        {:noreply,
         socket
         |> assign(:room_code, code)
         |> assign(:room, room_details)
         |> assign(:is_host, is_host)
         |> assign(:games, games)
         |> apply_action(socket.assigns.live_action, params)}
    end
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, push_navigate(socket, to: "/", replace: true)}
  end

  @impl Phoenix.LiveView
  def handle_info({:room_updated, room}, socket) do
    {:noreply, assign(socket, :room, room)}
  end

  @impl Phoenix.LiveView
  def handle_event("pick_game", %{"game_id" => game_id}, socket) do
    case Playground.RoomProcess.start_game(%{code: socket.assigns.room_code, game_id: game_id}) do
      {:error, :room_not_found} ->
        {:noreply, push_navigate(socket, to: "/", replace: true)}

      {:ok, _} ->
        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_event(
        "tic-tac-toe-move",
        %{"row_index" => row_index, "col_index" => col_index},
        socket
      ) do
    Playground.RoomProcess.game_move(%{
      code: socket.assigns.room_code,
      player_id: socket.assigns.player_id,
      move: %{row: String.to_integer(row_index), col: String.to_integer(col_index)}
    })

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "back",
        _params,
        socket
      ) do
    Playground.RoomProcess.end_game(socket.assigns.room_code)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "tic-tac-toe-again",
        _params,
        socket
      ) do
    Playground.RoomProcess.end_game(socket.assigns.room_code)
    Playground.RoomProcess.start_game(%{code: socket.assigns.room_code, game_id: "tic-tac-toe"})

    {:noreply, socket}
  end

  def players_count(room) do
    Enum.count(room.players)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Welcome!")
  end
end
