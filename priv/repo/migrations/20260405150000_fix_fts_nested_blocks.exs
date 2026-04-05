defmodule Atlas.Repo.Migrations.FixFtsNestedBlocks do
  use Ecto.Migration

  def up do
    # Recursive function to extract all text from BlockNote JSON,
    # including nested children blocks
    execute """
    CREATE OR REPLACE FUNCTION sections_search_text_trigger() RETURNS trigger AS $$
    DECLARE
      plain text;
    BEGIN
      WITH RECURSIVE all_blocks AS (
        -- Top-level blocks
        SELECT b AS block
        FROM jsonb_array_elements(NEW.content) AS b

        UNION ALL

        -- Recurse into children arrays
        SELECT child AS block
        FROM all_blocks,
             jsonb_array_elements(all_blocks.block -> 'children') AS child
        WHERE jsonb_typeof(all_blocks.block -> 'children') = 'array'
          AND jsonb_array_length(all_blocks.block -> 'children') > 0
      )
      SELECT coalesce(string_agg(elem, ' '), '') INTO plain
      FROM (
        SELECT jsonb_array_elements(ab.block -> 'content') ->> 'text' AS elem
        FROM all_blocks ab
        WHERE jsonb_typeof(ab.block -> 'content') = 'array'
      ) sub
      WHERE elem IS NOT NULL;

      NEW.search_text := to_tsvector('english', plain);
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    """
  end

  def down do
    # Revert to the non-recursive version
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
end
