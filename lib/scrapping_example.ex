defmodule ScrappingExample do
  use OkJose
  alias ScrappingExample.Domain.PropertyNetAdProcessor

  def process() do
    IO.puts("Start processing..")
    process_per_page(1)
    
  end

  # Pipe.ok breaks the pipe.ing where result is not {:ok, _} and return the value that broke pipe.
  def process_per_page(page_num) do
    {:ok, page_num}
    |> get_page_url
    |> get_page_body
    |> Floki.parse_document
    |> get_ad_ids_if_any
    |> process_document_ads
    |> inc(page_num)
    |> process_per_page
    |> Pipe.ok
  end

  # Its hardcoded for maribor region
  defp get_page_url(page_num) do
    {:ok, "https://www.nepremicnine.net/oglasi-prodaja/podravska/maribor/stanovanje/#{page_num}/?s=16"}
  end

  defp get_page_body(url) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> {:ok, body}
      {:ok, %HTTPoison.Response{status_code: 404}} -> {:error, "HTTPoison: 404 for url: " <> url}
      {:error, %HTTPoison.Error{reason: reason}} -> 
        IO.inspect(reason, label: "HTTPoison error" ) # here would be a logger
        {:error, "HTTPoison error."}
    end
  end

  defp get_ad_ids_if_any(document) do
    ads_per_document = document |> Floki.find("div.seznam div.oglas_container")
    if length(ads_per_document) > 0 do
      {:ok, %{"document": document, "ad_ids": ads_per_document |> Floki.attribute("id")}}
    else
      {:error, "No ads in the document."}
    end
  end

  defp process_document_ads(%{"document": document, "ad_ids": ad_ids}) do
    ad_ids
    |> Enum.take_while(fn id -> scrapp_and_persist(document, id) end)
    |> compare_count_with(ad_ids) # if take_while did not process everything we return {:error, _} to break
  end

  defp scrapp_and_persist(document, id) do
    ad_as_dom = get_ad(document, id)
    href = get_ad_href(ad_as_dom)
    
    if (byte_size(href) > 0) do
      new_ad = %{
        uid: id,
        title: get_ad_title(ad_as_dom),
        href: href,
        description: get_ad_description(ad_as_dom),
        price: get_ad_price(ad_as_dom),
        price_before: get_ad_price_before(ad_as_dom),
        size: get_ad_size(ad_as_dom),
        agency: get_ad_agency(ad_as_dom),
        year_builded: get_ad_year(ad_as_dom),
        etage: get_ad_etage(ad_as_dom),
        zip_code: "2000",
      }

      new_ad
      |> PropertyNetAdProcessor.upsert_ad
      |> case do
        {:ok, result} -> 
          IO.puts "Upsert an ad - success with id: " <> id
          result
        _ = error -> 
          IO.puts "Upsert an ad - error with id: " <> id
          IO.inspect(error)
          false  # return falsy in case of error in order to stop enumerating ids
      end
    else
      # we skip ads without href (hidden ads DOMs on the page) and return truthy value to continue
      {:ok, id}
    end
  end

  # utility functions that return tupple in order to work with OkJose ie. Pipe.ok
  defp okj_inspect(value) do 
    IO.inspect(value, label: "OkJose inspect")
    {:ok, value}
  end

  defp inc(_, page_num), do: {:ok, page_num+1}

  defp compare_count_with(list, orig_list) do
    num = Enum.count(orig_list)

    list
    |> Enum.count
    |> case do
      ^num -> {:ok, list}
      _ -> {:error, list} end
  end

  defp get_ad(document, id) do
    document |> Floki.find("div.seznam div.oglas_container[id=#{id}] div[itemprop=item]")
  end

  defp get_ad_href(document) do
    document |> Floki.find("h2 a[itemprop=url]") |> Floki.attribute("href") |> Floki.text
  end

  defp get_ad_title(document) do
    document |> Floki.find("h2 a[itemprop=url] span[class=title]") |> Floki.text
  end

  defp get_ad_description(document) do
    document |> Floki.find("div[class=kratek_container] div[itemprop=description]") |> Floki.text
  end

  defp get_ad_price(document) do
    {price, _} = document |> Floki.find("div[class=main-data] meta[itemprop=price]") |> Floki.attribute("content") |> Floki.text |> Float.parse
    price
  end

  defp get_ad_price_before(document) do
    tmp = document |> Floki.find("span[class=cena] span[class=cena-old]") |> Floki.text
    if String.length(tmp) > 0 do
      {price, _} = String.slice(tmp, 0, String.length(tmp) - 2) |> String.replace(".", "") |> String.replace(",", ".") |> Float.parse
      price
    end
  end

  # "64,50 m2"
  defp get_ad_size(document) do
    size = document |> Floki.find("div[class=main-data] span[class=velikost]") |> Floki.text
    if String.length(size) > 0 do
      {size, _} = String.slice(size, 0, String.length(size) - 3) |> String.replace(",", ".") |> Float.parse
      size
    end
  end

  defp get_ad_agency(document) do
    document |> Floki.find("div[class=main-data] .agencija") |> Floki.text
  end

  defp get_ad_year(document) do
    {year, _} = document |> Floki.find("div[class=atributi] span[class='atribut leto'] strong") |> Floki.text |> Integer.parse
    year
  end

  defp get_ad_etage(document) do
    # It can be also a letter P as 'Pritlicje'
    document |> Floki.find("div[class=atributi] span[class=atribut] strong") |> Floki.text
  end
end
