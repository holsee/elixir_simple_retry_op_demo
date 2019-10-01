defmodule RetryDemoTest do
  use ExUnit.Case
  doctest RetryDemo

  test "greets the world" do
    assert RetryDemo.hello() == :world
  end
end
