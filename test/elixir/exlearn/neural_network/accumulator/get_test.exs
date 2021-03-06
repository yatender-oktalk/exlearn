defmodule ExLearn.NeuralNetwork.Accumulator.GetTest do
  use ExUnit.Case, async: true

  alias ExLearn.NeuralNetwork.Accumulator
  alias ExLearn.NeuralNetwork.Manager
  alias ExLearn.NeuralNetwork.Notification
  alias ExLearn.NeuralNetwork.Store

  setup do
    notification_name    = {:global, make_ref()}
    notification_args    = []
    notification_options = [name: notification_name]
    {:ok, _} = Notification.start_link(notification_args, notification_options)

    store_name    = {:global, make_ref()}
    store_args    = %{notification: notification_name}
    store_options = [name: store_name]
    {:ok, _} = Store.start_link(store_args, store_options)

    manager_name    = {:global, make_ref()}
    manager_args    = []
    manager_options = [name: manager_name]
    {:ok, _} = Manager.start_link(manager_args, manager_options)

    name = {:global, make_ref()}
    args = %{
      manager:      manager_name,
      notification: notification_name,
      store:        store_name
    }
    options = [name: name]

    {:ok, setup: %{
      args:       args,
      name:       name,
      options:    options,
      store_name: store_name
    }}
  end

  test "#get returns the initial result", %{setup: setup} do
    %{
      args:    args,
      name:    accumulator = {:global, reference},
      options: options
    } = setup

    {:ok, accumulator_pid} = Accumulator.start_link(args, options)

    assert Accumulator.get(accumulator) == :no_data

    pid_of_reference = :global.whereis_name(reference)

    assert accumulator_pid |> is_pid
    assert accumulator_pid |> Process.alive?
    assert reference       |> is_reference
    assert accumulator_pid == pid_of_reference
  end
end
