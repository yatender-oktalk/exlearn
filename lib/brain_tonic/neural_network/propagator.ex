defmodule BrainTonic.NeuralNetwork.Propagator do
  @moduledoc """
  Propagates input trough a network
  """

  alias BrainTonic.Calculator

  @doc """
  Propagates input forward trough a network and return the result
  """
  @spec feed_forward([number], [[[number]]]) :: [number]
  def feed_forward(input, network) do
    %{
      activations: activations,
      biases:      biases,
      weights:     weights
    } = network

    full_network = {[[input]|weights], [], []}

    feed_forward(full_network, biases, activations)
  end

  @spec feed_forward([[[number]]], [[number]], [function]) :: [number]
  defp feed_forward({[network|[]], weighted_input, activity}, _, _) do
    [result] = network
    {result, Enum.reverse(weighted_input), Enum.reverse(activity)}
  end

  defp feed_forward({[a, b | network], weighted_input, activity}, [c | biases], [d | activations]) do
    %{function: activation_function} = d
    input = Calculator.multiply(a, b)
      |> Calculator.add(c)

    result = input
      |> Calculator.apply(activation_function)

    new_activity       = result ++ activity
    new_weighted_input = input ++ weighted_input

    feed_forward({[result|network], new_weighted_input, new_activity}, biases, activations)
  end

  @doc """
  Performs backpropagation
  """
  @spec back_propagate(tuple, number, map) :: map
  def back_propagate(forwarded, cost_gradient, network) do
    {result, weighted_input, activity} = forwarded

    back_propagater(forwarded, cost_gradient, network)
  end

  def back_propagater(forwarded, cost_gradient, network) do
    {result, weighted_input, activity} = forwarded
    %{
      activations: activations,
      biases:      biases,
      weights:     weights
    } = network

    deltas = calculate_detlas(weights, cost_gradient, weighted_input, activations, [])
  end

  def calculate_detlas([], cost_gradient, [weighted_input], [activation], totals) do
    %{derivative: derivative} = activation

    delta = Calculator.dot_product(cost_gradient, derivative.(weighted_input))

    Enum.reverse([delta|totals])
  end

  def calculate_detlas([weight|weights], cost_gradient, [weighted_input|weighted_inputs], [activation|activations], [delta|totals]) do
    %{derivative: derivative} = activation

    delta = Calculator.dot_product(Calculator.dot_product(Calculator.trasnspose(weight), delta), derivative.(weighted_input))

    calculate_detlas(weights, cost_gradient, weighted_inputs, activations, totals)
  end
end
