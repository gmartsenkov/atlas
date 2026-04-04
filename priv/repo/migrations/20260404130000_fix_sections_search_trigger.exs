defmodule Atlas.Repo.Migrations.FixSectionsSearchTrigger do
  use Ecto.Migration

  def up do
    execute """
    CREATE OR REPLACE FUNCTION sections_search_text_trigger() RETURNS trigger AS $$
    DECLARE
      plain text;
    BEGIN
      SELECT coalesce(string_agg(elem, ' '), '') INTO plain
      FROM (
        SELECT jsonb_array_elements(block_content) ->> 'text' AS elem
        FROM (
          SELECT b -> 'content' AS block_content
          FROM jsonb_array_elements(NEW.content) AS b
          WHERE jsonb_typeof(b -> 'content') = 'array'
        ) block_contents
      ) sub
      WHERE elem IS NOT NULL;

      NEW.search_text := to_tsvector('english', plain);
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    """
  end

  def down do
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
end
