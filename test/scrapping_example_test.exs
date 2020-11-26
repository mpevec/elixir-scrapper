defmodule ScrappingExampleTest do
  use ExUnit.Case
  doctest ScrappingExample

  test "greets the world" do
    assert ScrappingExample.hello() == :world
  end
end
