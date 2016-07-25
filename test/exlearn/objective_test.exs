defmodule ObjectiveTest do
  use ExUnit.Case, async: true

  alias ExLearn.Objective

  test "#determine returns the given function pair" do
    first  = 1
    second = 2

    expected_from_function = 4
    expected_from_error    = 5

    given_function = &(&1 + &2 + 1)
    given_error    = &(&1 + &2 + 2)

    setup = %{function: given_function, error: given_error}

    %{function: function, error: error} = Objective.determine(setup)

    assert function.(first, second) == expected_from_function
    assert error.(first, second)    == expected_from_error
  end

  test "#determine returns the cross entropy function pair" do
    first     = [0.2, 0.2, 0.6]
    second    = [0.4, 0.5, 0.6]
    data_size = 1

    expected_from_function = 1.9580774929568254
    expected_from_error    = [0.2, 0.3, 0.0]

    setup = :cross_entropy

    %{function: function, error: error} = Objective.determine(setup)

    assert function.(first, second, data_size) == expected_from_function
    assert error.(first, second)               == expected_from_error
  end

  test "#determine returns the negative log likelihood function pair" do
    first     = [1,   0,   0  ]
    second    = [0.6, 0.3, 0.1]
    data_size = 1

    expected_from_function = 0.5108256237659907
    expected_from_error    = [-0.4, 0.3, 0.1]

    setup = :negative_log_likelihood

    %{function: function, error: error} = Objective.determine(setup)

    assert function.(first, second, data_size) == expected_from_function
    assert error.(first, second)               == expected_from_error
  end

  test "#determine returns the quadratic function pair" do
    first     = [1, 2, 3]
    second    = [1, 2, 7]
    data_size = 1

    expected_from_function = 8
    expected_from_error    = [0, 0, 4]

    setup = :quadratic

    %{function: function, error: error} = Objective.determine(setup)

    assert function.(first, second, data_size) == expected_from_function
    assert error.(first, second)               == expected_from_error
  end
end
