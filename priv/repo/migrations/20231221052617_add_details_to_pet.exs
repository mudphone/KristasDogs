defmodule KristasDogs.Repo.Migrations.AddDetailsToPet do
  use Ecto.Migration

  def change do
    alter table(:pets) do
      add :description, :string, null: true
      add :size, :string, null: true
      add :weight, :string, null: true
      add :altered, :boolean, null: true
      add :details_added_at, :utc_datetime, null: true
    end
  end
end
