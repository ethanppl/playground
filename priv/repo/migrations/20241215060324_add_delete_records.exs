defmodule Playground.Repo.Migrations.AddDeleteRecords do
  use Ecto.Migration

  alias Playground.MigrationHelper

  # No soft delete: https://brandur.org/fragments/deleted-record-insert
  def change do
    create table(:deleted_records,
             primary_key: [name: :id, type: :binary_id, default: fragment("gen_random_uuid()")]
           ) do
      add :data, :map, null: false
      add :object_id, :text, null: false
      add :table_name, :text, null: false

      timestamps(type: :timestamptz, default: fragment("NOW()"))
    end

    execute(
      """
      CREATE FUNCTION insert_deleted_record() RETURNS trigger
          LANGUAGE plpgsql
      AS $$
          BEGIN
              EXECUTE 'INSERT INTO deleted_records (data, object_id, table_name) VALUES ($1, $2, $3)'
              USING to_jsonb(OLD.*), OLD.id, TG_TABLE_NAME;

              RETURN OLD;
          END;
      $$;
      """,
      """
      DROP FUNCTION IF EXISTS insert_deleted_record() CASCADE;
      """
    )

    MigrationHelper.create_delete_trigger("rooms")
    MigrationHelper.create_delete_trigger("players")
    MigrationHelper.create_delete_trigger("games")
  end
end
