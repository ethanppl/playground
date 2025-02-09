defmodule PlaygroundWeb.RoomLive do
  use PlaygroundWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    if connected?(socket) and is_binary(session["room_code"]) do
      Phoenix.PubSub.subscribe(Playground.PubSub, session["room_code"])
    end

    {:ok,
     socket
     |> assign(:code_from_session, session["room_code"])
     |> assign(:player_id, session["user_id"])
     |> assign(:player_name, session["user_name"])
     |> assign(:is_info_modal_open, false)
     |> assign(:info_modal_show_how_to_play, nil)}
  end

  @impl Phoenix.LiveView
  def handle_params(
        %{"code" => code} = params,
        url,
        # The code in the URL has to match the code in the session
        %{assigns: %{code_from_session: code}} = socket
      ) do
    case Playground.RoomProcess.get_room_details(code) do
      {:error, :room_not_found} ->
        {:noreply,
         push_navigate(
           socket,
           to: "/?error=Sorry!+Cannot+find+room+#{code}",
           replace: true
         )}

      {:ok, room_details} ->
        is_host = room_details.host_id === socket.assigns.player_id

        games = get_games(room_details)

        join_room_link = String.replace(url, "/rooms/#{code}", "/join/#{code}")

        new_socket =
          socket
          |> assign(:room_code, code)
          |> assign(:room, room_details)
          |> assign(:is_host, is_host)
          |> assign(:games, games)
          |> assign(:join_room_link, join_room_link)
          |> apply_action(socket.assigns.live_action, params)

        maybe_redirect_viewer(room_details, new_socket)
    end
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    # If the viewer is not part of the room, redirect back to the home page
    {:noreply,
     push_navigate(
       socket,
       to: "/?error=Sorry!+You+are+not+part+of+the+room",
       replace: true
     )}
  end

  # If the viewer is not part of the room, redirect back to the home page
  defp maybe_redirect_viewer(room, socket, is_room_just_updated \\ false) do
    player_is_in_room =
      room
      |> Map.get(:players)
      |> Enum.find(fn player ->
        player.id == socket.assigns.player_id
      end)
      |> is_struct(Playground.DB.Player)

    cond do
      player_is_in_room == true ->
        {:noreply, socket}

      is_room_just_updated ->
        {:noreply, push_navigate(socket, to: ~p"/?error=Sorry!+You+are+removed+by+the+host")}

      true ->
        {:noreply, push_navigate(socket, to: ~p"/?error=Sorry!+You+are+not+part+of+the+room")}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:room_updated, room}, socket) do
    games = get_games(room)

    new_socket =
      socket
      |> assign(:room, room)
      |> assign(:games, games)

    maybe_redirect_viewer(room, new_socket, true)
  end

  def handle_info(
        {:room_notification,
         %{sender: _sender, receiver: receiver, message: message, type: type} = payload},
        socket
      ) do
    integer_player_id = socket.assigns.player_id
    string_player_id = "#{socket.assigns.player_id}"
    duration = Map.get(payload, :duration, 3000)

    case receiver do
      %{type: :broadcast} ->
        {:noreply, put_flash_and_schedule_clear(socket, type, message, duration)}

      %{type: :player, player: ^string_player_id} ->
        {:noreply, put_flash_and_schedule_clear(socket, type, message, duration)}

      %{type: :player, player: ^integer_player_id} ->
        {:noreply, put_flash_and_schedule_clear(socket, type, message, duration)}

      %{type: :broadcast_except, except: except} ->
        if Enum.any?(except, &(&1 == string_player_id or &1 == integer_player_id)) do
          {:noreply, socket}
        else
          {:noreply, put_flash_and_schedule_clear(socket, type, message, duration)}
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
        {:noreply,
         push_navigate(
           socket,
           to: "/?error=Sorry!+Cannot+find+room+#{socket.assigns.room_code}",
           replace: true
         )}

      {:error, :cannot_start_game} ->
        {:noreply,
         put_flash_and_schedule_clear(
           socket,
           :error,
           "Cannot start game, please try again!",
           3000
         )}

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

  def handle_event(
        "toggle-how-to-play",
        params,
        socket
      ) do
    case socket.assigns[:info_modal_show_how_to_play] do
      nil ->
        %{"game_id" => game_id} = params
        game_details = Playground.Games.get_game_details(game_id)

        {:noreply,
         socket
         |> assign(:info_modal_show_how_to_play, game_details)
         |> assign(:is_info_modal_open, true)}

      _game_details ->
        {:noreply, assign(socket, :info_modal_show_how_to_play, nil)}
    end
  end

  def handle_event("open_info_modal", _params, socket) do
    {:noreply, assign(socket, is_info_modal_open: true)}
  end

  def handle_event("close_info_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(is_info_modal_open: false)
     |> assign(info_modal_show_how_to_play: nil)}
  end

  def handle_event(
        "remove",
        params,
        socket
      ) do
    Playground.RoomProcess.remove_player(%{
      code: socket.assigns.room_code,
      player_id: String.to_integer(params["remove-player-id"])
    })

    {:noreply, socket}
  end

  def players_count(room) do
    Enum.count(room.players)
  end

  defp get_games(room_details) do
    Enum.map(Playground.Games.list_games(), fn game ->
      players_count = players_count(room_details)
      disabled = players_count < game.min_players or players_count > game.max_players

      Map.put(game, :disabled, disabled)
    end)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Welcome!")
  end
end
