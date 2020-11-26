defmodule ScrappingExample.Domain.PropertyNetAdProcessor do
  alias ScrappingExample.Repo
  alias ScrappingExample.Schema.PropertyNetAd

  def upsert_ad(new_ad) do
    upsert_multi = get_ad_by_uid(new_ad.uid) |> upsert_ad_multi(new_ad)

    # in case of error returns {:error, :insert_at, ...Ecto.Changeset...} otherwise {:ok, results}
    Ecto.Multi.new()
    |> Ecto.Multi.append(upsert_multi)
    |> Repo.transaction()
  end

  defp get_ad_by_uid(uid) do
    Repo.get_by(PropertyNetAd, uid: uid)
  end

  # pattern match implies that ad is not null so no need for is_nil guard
  defp upsert_ad_multi(%PropertyNetAd{} = ad, new_ad) do
    IO.puts("...update multi..")

    params = %{
      price: new_ad.price,
      price_before: new_ad.price_before
    }
    
    Ecto.Multi.new()
    |> Ecto.Multi.update(:update_ad, PropertyNetAd.update_price_changeset(ad, params))
  end

  defp upsert_ad_multi(_, new_ad) do
    IO.puts("...insert multi..")

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:insert_ad, PropertyNetAd.create_changeset(%PropertyNetAd{}, new_ad))
  end
end