defmodule PlaygroundWeb.JoinRoomFormComponent.JoinRoom do
  @moduledoc """
  A typed schema for the join room form
  """
  use Playground.DB.Schema
  import Ecto.Changeset

  typed_embedded_schema do
    field :player_name, :string
    field :code, :string
  end

  def changeset(room, attrs, opts \\ []) do
    room
    |> cast(attrs, [:player_name, :code])
    |> validate_required([:player_name, :code], opts)
    |> validate_length(:player_name, min: 1, max: 32)
    |> validate_length(:code, min: 4, max: 4)
    |> validate_room_code()
  end

  defp validate_room_code(%Ecto.Changeset{valid?: false, errors: errors} = changeset) do
    case errors[:code] do
      nil ->
        do_validate_room_code(changeset)

      _ ->
        changeset
    end
  end

  defp validate_room_code(changeset) do
    do_validate_room_code(changeset)
  end

  defp do_validate_room_code(changeset) do
    validate_change(changeset, :code, fn :code, code ->
      case Playground.RoomProcess.whereis(code) do
        nil ->
          [code: {"Room #{code} not found", additional: "info"}]

        _ ->
          []
      end
    end)
  end
end

defmodule PlaygroundWeb.JoinRoomFormComponent do
  @moduledoc """
  A live component for creating the join room form
  """
  use PlaygroundWeb, :live_component

  alias PlaygroundWeb.JoinRoomFormComponent.JoinRoom

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
      </.header>

      <.simple_form
        for={@form}
        id="post-form"
        action={~p"/join_room"}
        phx-target={@myself}
        phx-change="validate"
        phx-submit="submit"
        phx-trigger-action={@trigger_submit}
        phx-hook="CtrlEnterSubmit"
      >
        <.input
          field={@form[:code]}
          type="text"
          label="ROOM CODE"
          helper="Enter the 4 letters room code from your friend"
          class="uppercase"
          autocomplete="off"
          phx-target={@myself}
          phx-mounted={
            if @form[:code].value == "", do: JS.focus() |> IO.inspect(label: "focus room code")
          }
        />
        <.input
          field={@form[:player_name]}
          type="text"
          label="NAME"
          helper="Enter your name, a name recognizable by your friends :)"
          class="uppercase"
          phx-target={@myself}
          phx-connected={
            if @form[:code].value != "", do: JS.focus() |> IO.inspect(label: "focus player")
          }
        />
        <:actions>
          <.button phx-disable-with="Joining...">Join!</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, assign(socket, trigger_submit: false)}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    changeset =
      JoinRoom.changeset(
        %JoinRoom{},
        %{player_name: "", code: assigns.room["room_code"]},
        validate_length: false
      )

    {:ok, socket |> assign(assigns) |> assign_form(changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"join_room" => join_room_params}, socket) do
    changeset =
      JoinRoom.changeset(
        %JoinRoom{},
        %{
          player_name: String.upcase(join_room_params["player_name"]),
          code: String.upcase(join_room_params["code"])
        }
      )

    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  def handle_event("submit", %{"join_room" => join_room_params}, socket) do
    validation =
      %JoinRoom{}
      |> JoinRoom.changeset(join_room_params)
      |> Ecto.Changeset.apply_action(:insert)

    case validation do
      {:ok, _changeset} ->
        {:noreply, assign(socket, trigger_submit: true)}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "join_room")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
