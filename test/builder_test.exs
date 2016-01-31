defmodule BuilderTest do
  use ExUnit.Case

  alias BrainTonic.NeuralNetwork.Builder, as: B

  test "initialize_neural_network return a map" do
    parameters = %{
      hidden_layers_sizes: [2, 3],
      hidden_layers_number: 2,
      input_size: 4,
      learning_rate: 0.5,
      output_layer_size: 5
    }
    result = parameters |> B.initialize_neural_network
    assert result |> is_map
  end
end
