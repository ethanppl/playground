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
     |> assign(:player_name, session["user_name"])
     |> assign(:is_info_modal_open, false)}
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

  def handle_info(
        {:room_notification,
         %{sender: _sender, receiver: receiver, message: message, type: type} = payload},
        socket
      ) do
    integer_player_id = socket.assigns.player_id
    string_player_id = "#{socket.assigns.player_id}"

    duration =
      case payload[:duration] do
        nil -> 3000
        _non_nil -> payload.duration
      end

    case receiver do
      %{type: :broadcast} ->
        {:noreply, put_flash_and_schedule_clear(socket, type, message, duration)}

      %{type: :player, player: ^string_player_id} ->
        {:noreply, put_flash_and_schedule_clear(socket, type, message, duration)}

      %{type: :player, player: ^integer_player_id} ->
        {:noreply, put_flash_and_schedule_clear(socket, type, message, duration)}

      %{type: :broadcast_except, except: except} ->
        if not Enum.any?(except, &(&1 == string_player_id or &1 == integer_player_id)) do
          {:noreply, put_flash_and_schedule_clear(socket, type, message, duration)}
        else
          {:noreply, socket}
        end

      _others ->
        {:noreply, socket}
    end
  end

  def handle_info(:clear_flash, socket) do
    {:noreply, clear_flash(socket)}
  end

  def handle_info(
        {:moved, move},
        socket
      ) do
    Playground.RoomProcess.game_move(%{
      code: socket.assigns.room_code,
      player_id: socket.assigns.player_id,
      move: move
    })

    if socket.assigns[:clear_flash_timer] do
      Process.cancel_timer(socket.assigns[:clear_flash_timer])
    end

    {:noreply, clear_flash(socket, :notif)}
  end

  defp put_flash_and_schedule_clear(socket, type, message, duration) do
    clear_flash_timer = Process.send_after(self(), :clear_flash, duration)

    socket
    |> assign(:clear_flash_timer, clear_flash_timer)
    |> put_flash(type, message)
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

  def handle_event(
        "back",
        _params,
        socket
      ) do
    Playground.RoomProcess.end_game(socket.assigns.room_code)

    {:noreply,
     socket
     |> clear_flash()
     |> assign(:is_info_modal_open, false)}
  end

  def handle_event(
        "again",
        _params,
        socket
      ) do
    Playground.RoomProcess.end_game(socket.assigns.room_code)

    Playground.RoomProcess.start_game(%{
      code: socket.assigns.room_code,
      game_id: socket.assigns.room.active_game.type
    })

    if socket.assigns[:clear_flash_timer] do
      Process.cancel_timer(socket.assigns[:clear_flash_timer])
    end

    {:noreply,
     socket
     |> clear_flash()
     |> assign(:is_info_modal_open, false)}
  end

  def handle_event("open_info_modal", _params, socket) do
    {:noreply, assign(socket, is_info_modal_open: true)}
  end

  def handle_event("close_info_modal", _params, socket) do
    {:noreply, assign(socket, is_info_modal_open: false)}
  end

  def players_count(room) do
    Enum.count(room.players)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Welcome!")
  end
end
