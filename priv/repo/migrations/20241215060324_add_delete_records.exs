defmodule Playground.Repo.Migrations.AddDeleteRecords do
  use Ecto.Migration

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

    execute(
      """
      CREATE TRIGGER trigger_rooms_delete AFTER DELETE ON rooms
          FOR EACH ROW EXECUTE FUNCTION insert_deleted_record();
      """,
      """
      DROP TRIGGER IF EXISTS trigger_rooms_delete on public.tickets
      """
    )

    execute(
      """
      CREATE TRIGGER trigger_games_delete AFTER DELETE ON games
          FOR EACH ROW EXECUTE FUNCTION insert_deleted_record();
      """,
      """
      DROP TRIGGER IF EXISTS trigger_games_delete on public.tickets
      """
    )

    execute(
      """
      CREATE TRIGGER trigger_players_delete AFTER DELETE ON players
          FOR EACH ROW EXECUTE FUNCTION insert_deleted_record();
      """,
      """
      DROP TRIGGER IF EXISTS trigger_players_delete on public.tickets
      """
    )
  end
end
