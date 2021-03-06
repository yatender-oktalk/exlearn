#include "../../../native/include/neural_network/forwarder.h"

#include "../fixtures/network_state_fixtures.c"
#include "../fixtures/data_fixtures.c"

static void test_forward_for_activity() {
  NetworkState *network_state = network_state_basic();
  Matrix        sample        = data_sample_basic();
  Activation   *activity      = forward_for_activity(network_state, sample);

  assert(activity->layers == network_state->layers); /* LCOV_EXCL_BR_LINE */

  float layer_1_input[5] = {1, 3, 31, 38, 45};
  float layer_2_input[4] = {1, 2, 371, 486};
  float layer_3_input[4] = {1, 2, 1830, 2688};

  assert(activity->input[0] == NULL); /* LCOV_EXCL_BR_LINE */
  assert(matrix_equal(activity->input[1], layer_1_input)); /* LCOV_EXCL_BR_LINE */
  assert(matrix_equal(activity->input[2], layer_2_input)); /* LCOV_EXCL_BR_LINE */
  assert(matrix_equal(activity->input[3], layer_3_input)); /* LCOV_EXCL_BR_LINE */

  float layer_0_output[5] = {1, 3, 1, 2, 3};
  float layer_1_output[5] = {1, 3, 31, 38, 45};
  float layer_2_output[4] = {1, 2, 371, 486};
  float layer_3_output[4] = {1, 2, 1830, 2688};

  assert(matrix_equal(activity->output[0], layer_0_output)); /* LCOV_EXCL_BR_LINE */
  assert(matrix_equal(activity->output[1], layer_1_output)); /* LCOV_EXCL_BR_LINE */
  assert(matrix_equal(activity->output[2], layer_2_output)); /* LCOV_EXCL_BR_LINE */
  assert(matrix_equal(activity->output[3], layer_3_output)); /* LCOV_EXCL_BR_LINE */

  assert(activity->mask[0] == NULL); /* LCOV_EXCL_BR_LINE */
  assert(activity->mask[1] == NULL); /* LCOV_EXCL_BR_LINE */
  assert(activity->mask[2] == NULL); /* LCOV_EXCL_BR_LINE */
  assert(activity->mask[3] == NULL); /* LCOV_EXCL_BR_LINE */

  activation_free(&activity);
  matrix_free(&sample);
  network_state_free(&network_state);
}

static void test_forward_for_activity_with_dropout() {
  NetworkState *network_state = network_state_with_dropout();
  Matrix        sample        = data_sample_basic();
  Activation   *activity      = forward_for_activity(network_state, sample);

  assert(activity->layers == network_state->layers); /* LCOV_EXCL_BR_LINE */

  assert(activity->mask[0] != NULL); /* LCOV_EXCL_BR_LINE */
  assert(activity->mask[1] != NULL); /* LCOV_EXCL_BR_LINE */
  assert(activity->mask[2] != NULL); /* LCOV_EXCL_BR_LINE */
  assert(activity->mask[3] != NULL); /* LCOV_EXCL_BR_LINE */

  activation_free(&activity);
  matrix_free(&sample);
  network_state_free(&network_state);
}

static void test_forward_for_output() {
  NetworkState *network_state = network_state_basic();
  Matrix        sample        = data_sample_basic();
  Matrix        output;
  int32_t       result;

  output = forward_for_output(network_state, sample);
  result = presentation_closure_call(network_state->presentation, output);

  assert(result == 1); /* LCOV_EXCL_BR_LINE */

  matrix_free(&output);
  matrix_free(&sample);
  network_state_free(&network_state);
}
