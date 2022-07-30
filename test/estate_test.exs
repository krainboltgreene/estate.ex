defmodule Example do
  import Estate

  state_machines(
    onboarding_state: [
      complete: [pending: "active"]
    ]
  )
end

defmodule EstateTest do
  use ExUnit.Case
  doctest Estate

  test "greets the world" do
    assert Estate.hello() == :world
  end
end
