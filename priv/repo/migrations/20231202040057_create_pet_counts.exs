defmodule KristasDogs.Repo.Migrations.CreatePetCounts do
  use Ecto.Migration

  def change do
    create table(:pet_counts) do
      add :counter_type, :string, null: false
      add :count, :integer, null: false, default: 0
      add :count_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
