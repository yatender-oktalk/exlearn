defmodule ExLearn.NeuralNetwork.Worker do
  use GenServer

  alias ExLearn.Matrix
  alias ExLearn.NeuralNetwork.{Forwarder, Notification, Propagator, Store}

  # Client API

  @spec prepare(map, any) :: any
  def prepare(network_state, worker) do
    GenServer.call(worker, {:prepare, network_state}, :infinity)
  end

  @spec work(:ask, any) :: any
  def work(:ask, worker) do
    GenServer.call(worker, :ask, :infinity)
  end

  @spec work(:test, any) :: any
  def work(:test, worker) do
    GenServer.call(worker, :test, :infinity)
  end

  @spec work(:train, any) :: any
  def work(:train, worker) do
    GenServer.call(worker, :train, :infinity)
  end

  @spec start([{}], map) :: {}
  def start(args, options) do
    GenServer.start( __MODULE__, args, options)
  end

  @spec start_link([{}], map) :: {}
  def start_link(args, options) do
    GenServer.start_link(__MODULE__, args, options)
  end

  # Server API

  @spec init(any) :: {}
  def init(data, configuration) do
    state = %{
      current_batch:     :not_set,
      configuration:     configuration,
      data:              data,
      network_state:     :not_set,
      remaining_batches: :not_set,
    }

    {:ok, state}
  end

  @spec handle_call({}, any,  map) :: {}
  def handle_call({:prepare, network_state}, state) do
    %{
      configuration: %{batch_size: batch_size},
      data:          data
    } = state

    [current_batch|remaining_batches] = Enum.chunk(data, batch_size)

    new_state = Map.put(state, :current_batch, current_batch)
    |> Map.put(:netwrok_state,     network_state)
    |> Map.put(:remaining_batches, remaining_batches)

    {:reply, result, new_state}
  end

  @spec handle_call({}, any,  map) :: {}
  def handle_call({:ask, batch}, _from,  state) do
    %{
      notification: notification,
      store:        store
    } = state

    network_state = Store.get_state(state)

    Notification.push("Asking", notification)
    result = ask_network(batch, network_state)
    Notification.push("Finished Asking", notification)

    {:reply, result, state}
  end

  @spec handle_call({}, any, map) :: {}
  def handle_call({:test, batch, configuration}, _from, state) do
    %{
      notification: notification,
      store:        store
    } = state

    network_state = Store.get_state(store)

    Notification.push("Testing", notification)
    result = test_network(batch, configuration, network_state)
    Notification.push("Finished Testing", notification)

    {:reply, result, state}
  end

  @spec handle_call({}, any, map) :: {}
  def handle_call(:train, _from, state) do
    correction = train_network(batch, configuration, network_state)

    {:reply, correction, state}
  end

  # Internal functions

  defp ask_network(batch, state) do
    Enum.map(batch, &Forwarder.forward_for_output(&1, state))
  end

  defp test_network(batch, configuration, state) do
    outputs = Enum.map(batch, &Forwarder.forward_for_test(&1, state))

    %{network: %{objective: %{function: objective}}} = state
    %{data_size: data_size} = configuration

    targets = Enum.map(batch, fn ({_, target}) -> target end)

    costs = Enum.zip(targets, outputs)
    |> Enum.map(fn ({target, output}) ->
      %{output: output_for_objective} = output

      objective.(target, output_for_objective, data_size)
    end)

    {outputs, costs}
  end

  @spec train_network(list, map, map) :: map
  defp train_network([sample|batch], configuration, state) do
    correction = train_sample(sample, configuration, state)

    train_network(batch, correction, configuration, state)
  end

  defp train_network([], correction, _, _) do
    total_correction
  end

  defp train_network([sample|batch], total_correction, configuration, state) do
    correction     = train_sample(sample, configuration, state)
    new_correction = accumulate_correction(correction, total_correction)

    train_network(batch, new_correction, configuration, state)
  end

  defp accumulate_correction(correction, total) do
    {bias_correction, weight_correction} = correction
    {bias_total,      weight_total     } = total

    bias_final = Enum.zip(bias_correction, bias_total)
    |> Enum.map(fn({x, y}) -> Matrix.add(x, y) end)

    weight_final = Enum.zip(weight_correction, weight_total)
    |> Enum.map(fn({x, y}) -> Matrix.add(x, y) end)

    {bias_final, weight_final}
  end

  defp train_sample(sample, configuration, state) do
    Forwarder.forward_for_activity(sample, state)
    |> Propagator.back_propagate(configuration, state)
  end
end
