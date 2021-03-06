#ifndef INCLUDED_WORKER_DATA_H
#define INCLUDED_WORKER_DATA_H

#include <stdint.h>
#include <stdlib.h>

#include "./bundle_paths.h"
#include "./worker_data_bundle.h"

typedef struct WorkerData {
  int32_t            count;
  WorkerDataBundle **bundle;
} WorkerData;

void
worker_data_free(WorkerData **data_address);

void
worker_data_inspect(WorkerData *worker_data);

void
worker_data_inspect_internal(WorkerData *worker_data, int32_t indentation);

WorkerData *
worker_data_new(int32_t count);

void
worker_data_initialize(WorkerData *worker_data, int32_t count);

void
worker_data_read(BundlePaths *paths, WorkerData *data);

#endif
