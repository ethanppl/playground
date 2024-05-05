defmodule Playground.Engine do
  @moduledoc """
  The driver of the playground
  """
  use DynamicSupervisor

  alias Playground.Rooms
  alias Playground.RoomProcess

  def start_link(init_arg) do
    case DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end

  def create_room(%{host_name: host_name} = opts) when is_binary(host_name) do
    case Rooms.create_room(opts) do
      {:ok, room} -> start_room_process(room)
      {:error, reason} -> {:error, reason}
    end
  end

  def start_room_process(room) do
    case DynamicSupervisor.start_child(__MODULE__, {RoomProcess, room}) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end

    {:ok, room}
  end

  @impl DynamicSupervisor
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
