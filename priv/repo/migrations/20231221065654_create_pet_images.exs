defmodule KristasDogs.Repo.Migrations.CreatePetImages do
  use Ecto.Migration

  def change do
    create table(:pet_images) do
      add :url, :string, null: false
      add :pet_id, references(:pets, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:pet_images, [:pet_id])
  end
end
