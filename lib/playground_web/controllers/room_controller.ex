defmodule PlaygroundWeb.RoomController do
  use PlaygroundWeb, :controller

  def new(conn, %{"new_room" => %{"host_name" => host_name}}) do
    case Playground.Engine.create_room(%{host_name: host_name}) do
      {:ok, room} ->
        conn
        |> Plug.Conn.put_session(:user_name, String.upcase(host_name))
        |> Plug.Conn.put_session(:user_id, room.host_id)
        |> Plug.Conn.put_session(:room_code, room.code)
        |> redirect(to: ~p"/rooms/#{room.code}")

      {:error, error} ->
        json(conn, %{message: "failed to create room", error: error})
    end
  end

  def join(conn, %{"join_room" => %{"code" => code, "player_name" => player_name}}) do
    case Playground.RoomProcess.join_room(%{code: code, player_name: player_name}) do
      {:ok, %{room: room, player: player}} ->
        conn
        |> Plug.Conn.put_session(:user_name, player.name)
        |> Plug.Conn.put_session(:user_id, player.id)
        |> Plug.Conn.put_session(:room_code, room.code)
        |> redirect(to: ~p"/rooms/#{code}")

      {:error, error} ->
        json(conn, %{message: "failed to create room", error: error})
    end
  end

  def quit(conn, _params) do
    room_code = get_session(conn, :room_code)
    player_id = get_session(conn, :user_id)

    if is_binary(room_code) and is_number(player_id) do
      Playground.RoomProcess.remove_player(%{
        code: room_code,
        player_id: player_id
      })
    end

    conn
    |> Plug.Conn.delete_session(:user_name)
    |> Plug.Conn.delete_session(:user_id)
    |> Plug.Conn.delete_session(:room_code)
    |> redirect(to: ~p"/")
  end
end
