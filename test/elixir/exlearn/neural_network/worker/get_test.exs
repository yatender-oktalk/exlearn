defmodule ExLearn.NeuralNetwork.Worker.GetTest do
  use ExUnit.Case, async: true

  alias ExLearn.NeuralNetwork.Worker

  setup do
    name    = {:global, make_ref()}
    options = [name: name]

    {:ok, setup: %{
      name:          name,
      options:       options,
    }}
  end

  test "#get returns the initial result", %{setup: setup} do
    %{
      name:    worker = {:global, reference},
      options: options
    } = setup

    args = %{data: %{location: :file, source: []}}

    {:ok, worker_pid} = Worker.start_link(args, options)

    assert Worker.get(worker) == :no_data

    pid_of_reference = :global.whereis_name(reference)

    assert worker_pid |> is_pid
    assert worker_pid |> Process.alive?
    assert reference  |> is_reference
    assert worker_pid == pid_of_reference
  end
end
