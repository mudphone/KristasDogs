defmodule KristasDogs.Repo.Migrations.AddNormalizedColumnsToPets do
  use Ecto.Migration

  def change do
    alter table(:pets) do
      add :normal_primary_breed, :string, null: true
      add :normal_age_months, :integer, null: true
      add :normal_weight_lbs, :float, null: true
    end
  end
end
