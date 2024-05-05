defmodule Playground.RoomsTest do
  use Playground.DataCase

  alias Playground.Rooms

  describe "get_room_details/1" do
    test("error when room does not exist") do
      assert {:error, :room_not_found} = Rooms.get_room_details("ABCD")
    end

    test("cannot get room details of inactive room") do
      room_fixture = insert(:room, %{status: :killed})

      assert {:error, :room_not_found} = Rooms.get_room_details(room_fixture.code)
    end

    Enum.each([:open, :playing], fn status ->
      test("can get room details of #{status} room") do
        room_fixture = insert(:room, %{status: unquote(status)})
        insert(:player, %{room_id: room_fixture.id})
        insert(:player, %{room_id: room_fixture.id})

        assert {:ok, room} = Rooms.get_room_details(room_fixture.code)

        assert room.id == room_fixture.id
        assert room.code == room_fixture.code
        assert room.status == unquote(status)
        assert Enum.count(room.players) == 2
      end
    end)
  end

  describe("create_room/1") do
    test("creates a room") do
      assert {:ok, room1} = Rooms.create_room(%{host_name: "John"})
      assert {:ok, room2} = Rooms.create_room(%{host_name: "John"})
      assert {:ok, room3} = Rooms.create_room(%{host_name: "Ben"})

      {:ok, db_room1} = Rooms.get_room_details(room1.code)
      {:ok, db_room2} = Rooms.get_room_details(room2.code)
      {:ok, db_room3} = Rooms.get_room_details(room3.code)

      assert db_room1.code == room1.code
      assert db_room1.host.name == "JOHN"
      assert db_room1.players == [db_room1.host]
      assert db_room1.active_game == nil

      assert db_room2.code == room2.code
      assert db_room2.host.name == "JOHN"
      assert db_room2.players == [db_room2.host]
      assert db_room2.active_game == nil

      assert db_room3.code == room3.code
      assert db_room3.host.name == "BEN"
      assert db_room3.players == [db_room3.host]
      assert db_room3.active_game == nil

      assert db_room1.code != db_room2.code
      assert db_room1.code != db_room3.code
      assert db_room2.code != db_room3.code
    end
  end

  describe("join_room/1") do
    test("error when room does not exist") do
      assert {:error, :room_not_found} = Rooms.join_room(%{code: "ABCD", player_name: "name"})
    end

    test("joins a room") do
      assert {:ok, room} = Rooms.create_room(%{host_name: "John"})

      assert {:ok, %{room: updated_room, player: player}} =
               Rooms.join_room(%{code: room.code, player_name: "Ben"})

      assert room.code == updated_room.code
      assert updated_room.host.name == "JOHN"
      assert Enum.count(updated_room.players) == 2

      assert player.name == "BEN"
      assert player.room_id == updated_room.id
    end
  end

  describe("start_game/2") do
    test("error when room does not exist") do
      assert {:error, :room_not_found} = Rooms.start_game(%{code: "ABCD", game_id: "tic-tac-toe"})
    end

    test("error when room is not active") do
      room_fixture = insert(:room, %{status: :killed})

      assert {:error, :room_not_found} =
               Rooms.start_game(%{code: room_fixture.code, game_id: "tic-tac-toe"})
    end

    test("starts a game") do
      {:ok, room_fixture} = Rooms.create_room(%{host_name: "John"})

      assert {:ok, updated_room} =
               Rooms.start_game(%{code: room_fixture.code, game_id: "tic-tac-toe"})

      assert updated_room.code == room_fixture.code
      assert updated_room.status == :playing
      assert updated_room.active_game.type == "tic-tac-toe"
    end
  end
end
