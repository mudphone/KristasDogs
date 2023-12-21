defmodule KristasDogs.Repo.Migrations.AddDetailsCheckedAtToPets do
  use Ecto.Migration

  def change do
    alter table(:pets) do
      add :details_checked_at, :utc_datetime, null: true
    end
  end
end
