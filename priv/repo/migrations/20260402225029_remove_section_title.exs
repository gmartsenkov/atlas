defmodule Atlas.Repo.Migrations.RemoveSectionTitle do
  use Ecto.Migration

  def up do
    alter table(:sections) do
      remove :title
    end

    # Update FTS trigger to not reference title
    execute """
    CREATE OR REPLACE FUNCTION sections_search_text_trigger() RETURNS trigger AS $$
    DECLARE
      plain text;
    BEGIN
      SELECT coalesce(string_agg(elem, ' '), '') INTO plain
      FROM (
        SELECT jsonb_array_elements(
          jsonb_array_elements(NEW.content) -> 'content'
        ) ->> 'text' AS elem
      ) sub
      WHERE elem IS NOT NULL;

      NEW.search_text := to_tsvector('english', plain);
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    """
  end

  def down do
    alter table(:sections) do
      add :title, :text
    end

    execute """
    CREATE OR REPLACE FUNCTION sections_search_text_trigger() RETURNS trigger AS $$
    DECLARE
      plain text;
    BEGIN
      SELECT coalesce(string_agg(elem, ' '), '') INTO plain
      FROM (
        SELECT jsonb_array_elements(
          jsonb_array_elements(NEW.content) -> 'content'
        ) ->> 'text' AS elem
      ) sub
      WHERE elem IS NOT NULL;

      NEW.search_text := to_tsvector('english', coalesce(NEW.title, '') || ' ' || plain);
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    """
  end
end
