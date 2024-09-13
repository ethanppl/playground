defmodule PlaygroundWeb.NewRoomFormComponent.NewRoom do
  @moduledoc """
  A typed schema for the new room form
  """
  use Playground.DB.Schema
  import Ecto.Changeset

  typed_embedded_schema do
    field :host_name, :string
  end

  def changeset(room, attrs, opts \\ []) do
    room
    |> cast(attrs, [:host_name])
    |> validate_required([:host_name], opts)
    |> validate_length(:host_name, min: 1, max: 32)
  end
end

defmodule PlaygroundWeb.NewRoomFormComponent do
  @moduledoc """
  A live component for creating the new room form
  """
  use PlaygroundWeb, :live_component

  alias PlaygroundWeb.NewRoomFormComponent.NewRoom

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
        action={~p"/new_room"}
        phx-target={@myself}
        phx-change="validate"
        phx-submit="submit"
        phx-trigger-action={@trigger_submit}
        phx-hook="CtrlEnterSubmit"
      >
        <.input
          field={@form[:host_name]}
          type="text"
          label="NAME"
          helper="Enter your name, a name recognizable by your friends :)"
          phx-mounted={JS.focus()}
        />
        <:actions>
          <.button phx-disable-with="Creating...">Create!</.button>
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
      NewRoom.changeset(
        %NewRoom{},
        %{host_name: ""},
        validate_length: false
      )

    {:ok, socket |> assign(assigns) |> assign_form(changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"new_room" => new_room_params}, socket) do
    changeset =
      NewRoom.changeset(
        %NewRoom{},
        new_room_params
      )

    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  def handle_event("submit", %{"new_room" => new_room_params}, socket) do
    validation =
      %NewRoom{}
      |> NewRoom.changeset(new_room_params)
      |> Ecto.Changeset.apply_action(:insert)

    case validation do
      {:ok, _changeset} ->
        {:noreply, assign(socket, trigger_submit: true)}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "new_room")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
