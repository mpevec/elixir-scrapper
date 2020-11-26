defmodule ScrappingExample.Schema.PropertyNetAd do
  use Ecto.Schema
  import Ecto.Changeset
  alias ScrappingExample.Schema.ZipCode
  alias ScrappingExample.Repo

  @primary_key {:id_property_net_ad, :id, autogenerate: true}
  schema "property_net_ad" do
    field :uid, :string
    field :title, :string
    field :href, :string
    field :description, :string
    field :price, :decimal
    field :price_before, :decimal
    field :size, :decimal
    field :agency, :string
    field :year_builded, :integer
    field :etage, :string
    field :last_date_checked, :date
    field :zip_code, :string, virtual: true
    timestamps()

    # To pomeni ZipCode ima asociacijo 'belongs_to' z mano. Sicer preko njegovega primarnega kljuca (references)
    # in mojega foreign_keya
    # Pravilo, tisti ki ima foreight key ima belongs_to asociacijo
    belongs_to :zipcode, ScrappingExample.Schema.ZipCode,
      references: :id_zip_code,
      foreign_key: :id_zip_code
  end

  @fields ~w(uid title href price year_builded)a
  @create_fields @fields ++ ~w(description price_before size agency etage zip_code)a
  @required_fields @fields ++ ~w(id_zip_code last_date_checked)a

  def create_changeset(%__MODULE__{} = property_net_ad, params) do
    property_net_ad
    |> cast(params, @create_fields)
    |> put_zip_code()
    |> put_change(:last_date_checked, NaiveDateTime.utc_now |> NaiveDateTime.to_date)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:id_zip_code)
    |> unique_constraint(:uid)
  end

  def update_price_changeset(%__MODULE__{} = property_net_ad, params) do
    property_net_ad
    |> change(params)
    |> put_change(:last_date_checked, NaiveDateTime.utc_now |> NaiveDateTime.to_date)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:id_zip_code)
  end

  defp put_zip_code(%Ecto.Changeset{valid?: true} = changeset) do
    code = fetch_change!(changeset, :zip_code)
    zipCode = Repo.get_by(ZipCode, code: code)
    if (zipCode) do
      put_change(changeset, :id_zip_code, zipCode.id_zip_code)
    else
      changeset
    end
  end

  defp put_zip_code(changeset), do: changeset
end