#ifdef GOOGLE_CUDA
#define EIGEN_USE_GPU
#include "tensorflow/core/util/cuda_kernel_helper.h"
#include "transit_op.h"

using namespace tensorflow;

using GPUDevice = Eigen::GpuDevice;

// Define the CUDA kernel.
template <typename T>
__global__
void TransitCudaKernel(int                            grid_size,
                       const T*  __restrict__   const x,
                       const T*  __restrict__   const grid,
                       int                            size,
                       const int*  __restrict__ const indmin,
                       const int*  __restrict__ const indmax,
                       const T*  __restrict__   const z,
                       const T*  __restrict__   const r,
                       T*  __restrict__               delta)
{
  int index = blockIdx.x * blockDim.x + threadIdx.x;
  int stride = blockDim.x * gridDim.x;
  for (int i = index; i < size; i += stride) {
    delta[i] = transit::compute_delta<T>(grid_size, x, grid, indmin[i], indmax[i], z[i], r[i]);
  }
}

template <typename T>
void TransitFunctor<GPUDevice, T>::operator()(
    const GPUDevice& d, int grid_size, const T* const x, const T* const grid,
    int size, const int* const indmin, const int* const indmax, const T* const z, const T* const r, T* delta)
{
  CudaLaunchConfig config = GetCudaLaunchConfig(size, d);
  TransitCudaKernel<T>
      <<<config.block_count, config.thread_per_block, 0, d.stream()>>>(grid_size, x, grid, size, indmin, indmax, z, r, delta);
}

template struct TransitFunctor<GPUDevice, float>;
template struct TransitFunctor<GPUDevice, double>;

#endif  // GOOGLE_CUDA