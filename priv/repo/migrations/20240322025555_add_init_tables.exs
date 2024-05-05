defmodule Playground.Repo.Migrations.AddInitTables do
  use Ecto.Migration

  @room_status_enum [
    "'open'",
    "'playing'",
    "'killed'"
  ]
  def room_status_enum do
    create_query =
      "CREATE TYPE room_status AS ENUM (#{Enum.join(@room_status_enum, ",")})"

    drop_query = "DROP TYPE room_status"

    execute(create_query, drop_query)
  end

  @game_status_enum [
    "'active'",
    "'ended'"
  ]
  def game_status_enum do
    create_query =
      "CREATE TYPE game_status AS ENUM (#{Enum.join(@game_status_enum, ",")})"

    drop_query = "DROP TYPE game_status"

    execute(create_query, drop_query)
  end

  def change do
    room_status_enum()
    game_status_enum()

    create table(:rooms) do
      add :code, :string, null: false
      add :status, :room_status, null: false, default: "open"

      timestamps(type: :timestamptz, default: fragment("NOW()"))
    end

    create table(:games) do
      add :state, :map, null: false
      add :status, :game_status, null: false, default: "active"
      add :type, :string, null: false
      add :room_id, references(:rooms, on_delete: :delete_all), null: false

      timestamps(type: :timestamptz, default: fragment("NOW()"))
    end

    create table(:players) do
      add :name, :string

      add :room_id, references(:rooms, on_delete: :delete_all), null: false

      timestamps(type: :timestamptz, default: fragment("NOW()"))
    end

    alter table(:rooms) do
      add :host_id, references(:players, on_delete: :delete_all), null: true
    end
  end
end
