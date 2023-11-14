defmodule KristasDogs.Repo.Migrations.AddRemovedFromWebsiteAtToPets do
  use Ecto.Migration

  def change do
    alter table(:pets) do
      add :removed_from_website_at, :utc_datetime, default: nil, null: true
    end
  end
end
