defmodule ExLearn.NeuralNetwork.Worker do
  use GenServer

  alias ExLearn.NeuralNetwork.{Forwarder, Propagator}

  #----------------------------------------------------------------------------
  # Client API
  #----------------------------------------------------------------------------

  @spec start_link([tuple], map) :: tuple
  def start_link(args, options) do
    GenServer.start_link(__MODULE__, args, options)
  end

  @spec get(any) :: any
  def get(worker) do
    GenServer.call(worker, :get, :infinity)
  end

  @spec predict(map, any) :: any
  def predict(network_state, worker) do
    GenServer.cast(worker, {:predict, network_state})
  end

  @spec test(map, any) :: any
  def test(network_state, worker) do
    GenServer.cast(worker, {:test, network_state})
  end

  @spec train(map, any) :: any
  def train(network_state, worker) do
    GenServer.cast(worker, {:train, network_state})
  end

  #----------------------------------------------------------------------------
  # Server API
  #----------------------------------------------------------------------------

  @spec init(map) :: {:ok, map}
  def init(setup) do
    %{data: %{location: location, source: source}} = setup

    configuration = Map.get(setup, :configuration, %{})

    data    = load_data(source, location)
    batches = split_in_batches(data, configuration)

    state = %{
      batches:       batches,
      configuration: configuration,
      data:          data,
      result:        :no_data
    }

    {:ok, state}
  end

  @spec handle_call(tuple, any,  map) :: {:reply, list, map}
  def handle_call(:get, _from,  state) do
    %{result: result} = state

    new_state = Map.put(state, :result, :no_data)

    {:reply, result, new_state}
  end

  @spec handle_cast(tuple, map) :: {:reply, list, map}
  def handle_cast({:predict, network_state}, state) do
    %{data: data} = state

    result    = network_predict(data, network_state)
    new_state = Map.put(state, :result, result)

    {:noreply, new_state}
  end

  @spec handle_cast(tuple, map) :: {:reply, list, map}
  def handle_cast({:test, network_state}, state) do
    %{data: data} = state

    result    = network_test(data, network_state)
    new_state = Map.put(state, :result, result)

    {:noreply, new_state}
  end

  @spec handle_cast(tuple, map) :: {:noreply, map}
  def handle_cast({:train, network_state}, state) do
    new_state = network_train(network_state, state)

    {:noreply, new_state}
  end

  #----------------------------------------------------------------------------
  # Internal functions
  #----------------------------------------------------------------------------

  defp load_data(source, :memory), do: source
  defp load_data(source, :file  )  do
    Enum.reduce(source, [], &read_file/2)
  end

  @spec read_file(bitstring, list) :: list
  defp read_file(path, accumulator) do
    {:ok, binary} = File.read(path)
    data          = :erlang.binary_to_term(binary)

    prepend(data, accumulator)
  end

  defp prepend([],           accumulator), do: accumulator
  defp prepend([first|rest], accumulator)  do
    prepend(rest, [first|accumulator])
  end

  defp split_in_batches(data, configuration) do
    chunks = case Map.get(configuration, :batch_size) do
      nil        -> data
      batch_size -> Enum.chunk(data, batch_size, batch_size, [])
    end

    case chunks do
      []                  -> %{current: :not_set, remaining: :not_set }
      [current|remaining] -> %{current: current,  remaining: remaining}
    end
  end

  defp network_predict(data, network_state) do
    network_predict(data, network_state, [])
  end

  defp network_predict([], _, accumulator), do: accumulator
  defp network_predict([sample|rest], network_state, accumulator) do
    output = Forwarder.forward_for_output(sample, network_state)

    network_predict(rest, network_state, [output|accumulator])
  end

  defp network_train(network_state, state) do
    %{batches: %{current: current}} = state

    case current do
      :not_set -> Map.put(state, :result, :no_data)
      _        -> train_current_batch(network_state, state)
    end
  end

  defp train_current_batch(network_state, state) do
    %{
      batches: %{
        current:   current,
        remaining: remaining
      }
    } = state

    correction = train_network(current, network_state)

    case remaining do
      [] -> state_with_done(state, correction)
      _  -> state_with_continue(state, correction)
    end
  end

  def state_with_done(state, correction) do
    %{
      configuration: configuration,
      data:          data
    } = state

    new_batches = split_in_batches(data, configuration)

    state
    |> Map.put(:batches, new_batches        )
    |> Map.put(:result,  {:done, correction})
  end

  def state_with_continue(state, correction) do
    %{batches: %{
      remaining: [new_current|new_remaining]
    }} = state

    new_batches = %{current: new_current, remaining: new_remaining}

    state
    |> Map.put(:batches, new_batches            )
    |> Map.put(:result,  {:continue, correction})
  end

  @spec train_network(list, map, map) :: map
  defp train_network([sample|batch], network_state) do
    first_correction = train_sample(sample, network_state)

    train_network(batch, first_correction, network_state)
  end

  defp train_network([], correction, _), do: correction
  defp train_network([sample|batch], accumulator, network_state) do
    new_correction = train_sample(sample, network_state)
    result         = Propagator.reduce_correction(new_correction, accumulator)

    train_network(batch, result, network_state)
  end

  defp train_sample(sample, network_state) do
    Forwarder.forward_for_activity(sample, network_state)
    |> Propagator.back_propagate(network_state)
  end

  defp network_test(data, network_state) do
    network_test(data, network_state, {0, 0})
  end

  defp network_test([], _, accumulator), do: accumulator
  defp network_test([sample|rest], network_state, {total_error, total_match}) do
    %{network: %{presentation: presentation}} = network_state

    activity = Forwarder.forward_for_test(sample, network_state)
    %{error: error, expected: expected, output: output} = activity

    new_match = case presentation.(expected) == presentation.(output) do
      true  -> total_match + 1
      false -> total_match
    end

    network_test(rest, network_state, {total_error + error, new_match})
  end
end
