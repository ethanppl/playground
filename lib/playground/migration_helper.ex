defmodule Playground.MigrationHelper do
  @moduledoc """
  Module with helper function to run migrations
  """
  use Ecto.Migration

  @doc """
  Creates a trigger to insert to delete records
  """
  @spec create_delete_trigger(binary()) :: :ok
  def create_delete_trigger(table_name) do
    trigger_name = "trigger_" <> String.replace(table_name, ".", "_") <> "_delete"

    execute(
      """
      CREATE TRIGGER #{trigger_name} AFTER DELETE ON #{table_name}
          FOR EACH ROW EXECUTE FUNCTION insert_deleted_record();
      """,
      """
      DROP TRIGGER IF EXISTS #{trigger_name} on #{table_name}
      """
    )
  end
end
