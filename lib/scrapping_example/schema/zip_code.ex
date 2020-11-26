defmodule ScrappingExample.Schema.ZipCode do
  use Ecto.Schema

  @primary_key {:id_zip_code, :id, autogenerate: true}
  schema "zip_code" do
    field :code, :string
    field :name, :string
    
    # a to pomeni, da PropertyNetAd ima one-to-one "z mano", sicer preko mojega (references) 'id_zip_code'
    # in njegovega foreign_key.a 'id_zip_code'
    has_one :property, ScrappingExample.Schema.PropertyNetAd,
      references: :id_zip_code,
      foreign_key: :id_zip_code

    timestamps()
  end

end