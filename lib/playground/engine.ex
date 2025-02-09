defmodule Playground.Engine do
  @moduledoc """
  The driver of the playground
  """
  use DynamicSupervisor

  alias Playground.RoomProcess
  alias Playground.Rooms

  @doc """
  Starts the playground engine that drives all room
  """
  @spec start_link(map) :: {:ok, pid} | {:error, term}
  def start_link(init_arg) do
    case DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end

  @doc """
  Create a room given the host name
  """
  @spec create_room(%{host_name: String.t()}) :: {:ok, Playground.DB.Room.t()} | {:error, term}
  def create_room(%{host_name: host_name} = opts) when is_binary(host_name) do
    case Rooms.create_room(opts) do
      {:ok, room} -> start_room_process(room)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Start the process that manages a room
  """
  @spec start_room_process(Playground.DB.Room.t()) :: {:ok, Playground.DB.Room.t()}
  def start_room_process(room) do
    case DynamicSupervisor.start_child(__MODULE__, {RoomProcess, room}) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end

    {:ok, room}
  end

  @impl DynamicSupervisor
  @doc """
  Initializes the playground engine, set the strategy to :one_for_one
  """
  @spec init(map) :: :ignore | {:ok, map()}
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
