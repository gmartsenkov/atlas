defmodule Atlas.Repo.Migrations.MigrateContentToSections do
  use Ecto.Migration

  def up do
    # For each page with content, create one section row
    execute """
    INSERT INTO sections (title, content, sort_order, page_id, inserted_at, updated_at)
    SELECT
      p.title,
      CASE
        WHEN p.content IS NULL OR p.content = '[]'::jsonb THEN '[]'::jsonb
        ELSE p.content
      END,
      0,
      p.id,
      p.inserted_at,
      p.updated_at
    FROM pages p
    WHERE p.content IS NOT NULL AND p.content != '[]'::jsonb;
    """

    # For pages with empty/null content, create a default "Introduction" section
    execute """
    INSERT INTO sections (title, content, sort_order, page_id, inserted_at, updated_at)
    SELECT
      'Introduction',
      '[]'::jsonb,
      0,
      p.id,
      p.inserted_at,
      p.updated_at
    FROM pages p
    WHERE p.content IS NULL OR p.content = '[]'::jsonb;
    """
  end

  def down do
    # Move section content back to pages
    execute """
    UPDATE pages SET content = (
      SELECT s.content FROM sections s
      WHERE s.page_id = pages.id
      ORDER BY s.sort_order
      LIMIT 1
    );
    """

    execute "DELETE FROM sections;"
  end
end
