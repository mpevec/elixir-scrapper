import Config

config :scrapping_example, ScrappingExample.Repo,
  url: "ecto://investment_user:in272@localhost/investment"  

config :scrapping_example,
  ecto_repos: [ScrappingExample.Repo]