// Copyright 2023 The IREE Authors
//
// Licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#ifndef IREE_HAL_DRIVERS_HIP_NATIVE_EXECUTABLE_H_
#define IREE_HAL_DRIVERS_HIP_NATIVE_EXECUTABLE_H_

#include <stdint.h>

#include "iree/base/api.h"
#include "iree/base/tracing.h"
#include "iree/hal/api.h"
#include "iree/hal/drivers/hip/dynamic_symbols.h"
#include "iree/hal/drivers/hip/hip_headers.h"

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

typedef struct iree_hal_hip_kernel_info_t {
  // TODO(#18189): remove when using simplified bindings.
  iree_hal_pipeline_layout_t* layout;
  hipFunction_t function;
  uint32_t constant_count;
  uint32_t binding_count;
  // TODO(#18189): add bitfield indicating indirect bindings.
  uint32_t block_size[3];
  uint32_t shared_memory_size;

  IREE_TRACE(iree_string_view_t function_name;)
  IREE_TRACE(iree_string_view_t source_filename;)
  IREE_TRACE(uint32_t source_line;)
} iree_hal_hip_kernel_info_t;

// Creates an IREE executable from a HSACO module. The module may contain
// several kernels that can be extracted along with the associated block size.
iree_status_t iree_hal_hip_native_executable_create(
    const iree_hal_hip_dynamic_symbols_t* symbols, hipDevice_t device,
    const iree_hal_executable_params_t* executable_params,
    iree_allocator_t host_allocator, iree_hal_executable_t** out_executable);

// Returns the kernel launch parameters for the given |entry_point| in the
// |executable|.
iree_status_t iree_hal_hip_native_executable_entry_point_kernel_info(
    iree_hal_executable_t* executable, int32_t entry_point,
    iree_hal_hip_kernel_info_t* out_info);

#ifdef __cplusplus
}  // extern "C"
#endif  // __cplusplus

#endif  // IREE_HAL_DRIVERS_HIP_NATIVE_EXECUTABLE_H_