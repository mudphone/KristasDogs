defmodule KristasDogs.Repo.Migrations.CreatePets do
  use Ecto.Migration

  def change do
    create table(:pets) do
      add :name, :string
      add :data_id, :string
      add :age_text, :string
      add :gender, :string
      add :primary_breed, :string
      add :species, :string
      add :title, :string
      add :campus, :string
      add :location, :string
      add :details_url, :string
      add :profile_image_url, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:pets, [:data_id])
  end
end
