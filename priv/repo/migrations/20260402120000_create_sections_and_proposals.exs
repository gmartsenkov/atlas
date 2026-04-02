defmodule Atlas.Repo.Migrations.CreateSectionsAndProposals do
  use Ecto.Migration

  def up do
    # --- Sections table ---
    create table(:sections) do
      add :title, :text, null: false
      add :content, :jsonb, default: "[]"
      add :sort_order, :integer, null: false
      add :search_text, :tsvector
      add :page_id, references(:pages, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:sections, [:page_id])
    create index(:sections, [:page_id, :sort_order])
    create index(:sections, [:search_text], using: :gin)

    # FTS trigger: extract plain text from BlockNote JSON and build tsvector
    execute """
    CREATE OR REPLACE FUNCTION sections_search_text_trigger() RETURNS trigger AS $$
    DECLARE
      plain text;
    BEGIN
      -- Extract all "text" values from the BlockNote content JSON
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

    execute """
    CREATE TRIGGER sections_search_text_update
      BEFORE INSERT OR UPDATE ON sections
      FOR EACH ROW
      EXECUTE FUNCTION sections_search_text_trigger();
    """

    # --- Proposals table ---
    create table(:proposals) do
      add :status, :text, null: false, default: "pending"
      add :proposed_title, :text
      add :proposed_content, :jsonb, default: "[]"
      add :section_id, references(:sections, on_delete: :delete_all), null: false
      add :author_id, references(:users, on_delete: :delete_all), null: false
      add :reviewed_by_id, references(:users, on_delete: :nilify_all)
      add :reviewed_at, :utc_datetime

      timestamps()
    end

    create index(:proposals, [:section_id])
    create index(:proposals, [:section_id, :status])

    # --- Proposal comments table ---
    create table(:proposal_comments) do
      add :body, :text, null: false
      add :proposal_id, references(:proposals, on_delete: :delete_all), null: false
      add :author_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:proposal_comments, [:proposal_id])
  end

  def down do
    drop table(:proposal_comments)
    drop table(:proposals)

    execute "DROP TRIGGER IF EXISTS sections_search_text_update ON sections;"
    execute "DROP FUNCTION IF EXISTS sections_search_text_trigger();"

    drop table(:sections)
  end
end
