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
end
