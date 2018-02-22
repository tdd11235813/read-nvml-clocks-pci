#include <nvml.h>
#include <cuda_runtime.h>
#include <vector>
#include <string>
#include <stdexcept>
#include <iostream>
#include <algorithm>

#define CHECK_NVML(ans) check_nvml((ans), #ans, __FILE__, __LINE__)
#define CHECK_CUDA(ans) check_cuda((ans), #ans, __FILE__, __LINE__)

inline
void throw_error(int code,
                 const char* error_string,
                 const char* func,
                 const char* file,
                 int line) {
  std::cerr << error_string
            << " [" << code << "] "
            << file << ":" << line
            << " " << func
            << "\n";
  throw std::runtime_error("Error occurred.");
}

void check_cuda(cudaError_t code,  const char *func, const char *file, int line) {
  if (code != cudaSuccess) {
    throw_error(static_cast<int>(code),
                cudaGetErrorString(code), func, file, line);
  }
}

void check_nvml(nvmlReturn_t code,  const char *func, const char *file, int line) {
  if (code != NVML_SUCCESS) {
    throw_error(static_cast<int>(code),
                nvmlErrorString(code), func, file, line);
  }
}

// [not used] simple cuda info
void cuda_info() {
  cudaDeviceProp prop;
  size_t f=0, t=0;
  int ndevs = 0;
  CHECK_CUDA( cudaGetDeviceCount(&ndevs) );
  for(int i=0; i<ndevs; ++i) {
    CHECK_CUDA( cudaGetDeviceProperties(&prop, i) );
    CHECK_CUDA( cudaMemGetInfo(&f, &t) );
    std::cout << i << ": " << prop.name << '"'
              << ", CC, " << prop.major << '.' << prop.minor
              << ", PCI Bus ID, " << prop.pciBusID
              << ", PCI Device ID, " << prop.pciDeviceID
              << ", Multiprocessors, "<< prop.multiProcessorCount
              << ", Memory [MiB], "<< t/1048576
              << ", MemoryFree [MiB], " << f/1048576
              << ", ECC enabled, " << prop.ECCEnabled
              << ", MemClock [MHz], " << prop.memoryClockRate/1000
              << ", GPUClock [MHz], " << prop.clockRate/1000
              << "\n"
      ;
  }
}

// simple nvml info
void nvml_info(std::vector<std::string>& bus_ids) {
  unsigned int device_count, i;

  CHECK_NVML( nvmlInit() );

  CHECK_NVML( nvmlDeviceGetCount(&device_count) );
  if(device_count<1)
    throw std::runtime_error("No NVML devices found.");
  bus_ids.resize(device_count);
  for (i = 0; i < device_count; i++)
  {
    char name[64];
    nvmlDevice_t device = 0;
    nvmlPciInfo_t pci;
//    unsigned int power = 0;
    CHECK_NVML( nvmlDeviceGetHandleByIndex(i, &device));
    CHECK_NVML( nvmlDeviceGetName(device, name, sizeof(name)/sizeof(name[0])));
//    CHECK_NVML( nvmlDeviceGetPowerUsage(device, &power)); // probably not supported on geforce,quadro
    CHECK_NVML( nvmlDeviceGetPciInfo(device, &pci));
    std::cout << i << ": Dev Name, " << name
              << ", PCI Bus (domain:bus:dev), " << pci.busId
              << ", PCI Bus, " << pci.bus
              << ", PCI Domain, " << pci.domain
              << ", PCI Dev, " << pci.device
              << ", PCI DevID, " << pci.pciDeviceId
              << ", PCI SubsysID, " << pci.pciSubSystemId
//              << ", Power (W), " << 0.001*power
              << "\n";
    bus_ids[i] = std::string(pci.busId);
  }

  CHECK_NVML(nvmlShutdown());
}


// [not used] demonstrate a coordinated cuda/nvml access
void test_cuda_and_nvml_device(int dev) {
  nvmlDevice_t device;
  cudaDeviceProp prop;
  char name[NVML_DEVICE_NAME_BUFFER_SIZE];
  char pci_busid[NVML_DEVICE_PCI_BUS_ID_BUFFER_SIZE];
  CHECK_CUDA( cudaGetDeviceProperties(&prop, dev) );

  CHECK_CUDA( cudaDeviceGetPCIBusId( pci_busid, NVML_DEVICE_PCI_BUS_ID_BUFFER_SIZE, dev ) );
  CHECK_NVML( nvmlInit() );
  CHECK_NVML( nvmlDeviceGetHandleByPciBusId( pci_busid, &device ) );
  CHECK_NVML( nvmlDeviceGetName(device, name, NVML_DEVICE_NAME_BUFFER_SIZE) );
  bool equal = (strcmp(prop.name, name) == 0);
  std::cout << "Name (CUDA|NVML): " << prop.name << " | "<< name << " (" << (equal?"OK":"Mismatch") << ")\n";
  CHECK_NVML(nvmlShutdown());
}

void show_freqs(int dev, const std::vector<std::string> bus_ids) {
  nvmlDevice_t device = 0;
  cudaDeviceProp prop;
  CHECK_CUDA( cudaGetDeviceProperties(&prop, dev) );

  // get nvml device by cuda device
  char cuda_pci_busId[NVML_DEVICE_PCI_BUS_ID_BUFFER_SIZE];
  CHECK_CUDA( cudaDeviceGetPCIBusId( cuda_pci_busId, NVML_DEVICE_PCI_BUS_ID_BUFFER_SIZE, dev ) );
  CHECK_NVML( nvmlDeviceGetHandleByPciBusId( cuda_pci_busId, &device ) );
  nvmlPciInfo_t pci;
  CHECK_NVML( nvmlDeviceGetPciInfo(device, &pci));
//  nvmlClockType_t clock_type = NVML_CLOCK_GRAPHICS; // NVML_CLOCK_MEM
//  nvmlClockId_t clock_id = NVML_CLOCK_ID_CURRENT; // NVML_CLOCK_ID_APP_CLOCK_TARGET
  unsigned int clock = 0; // in Mhz
  unsigned int clock_current = 0; // in Mhz
  unsigned int clock_target = 0; // in Mhz
  unsigned int clock_mem = 0; // in Mhz
  unsigned int clock_current_mem = 0; // in Mhz
  unsigned int clock_target_mem = 0; // in Mhz
  CHECK_NVML(nvmlDeviceGetClockInfo(device, NVML_CLOCK_MEM, &clock_mem)); // current clock
  CHECK_NVML(nvmlDeviceGetClock(device, NVML_CLOCK_MEM, NVML_CLOCK_ID_CURRENT, &clock_current_mem));
  CHECK_NVML(nvmlDeviceGetClock(device, NVML_CLOCK_MEM, NVML_CLOCK_ID_APP_CLOCK_TARGET, &clock_target_mem));
  CHECK_NVML(nvmlDeviceGetClockInfo(device, NVML_CLOCK_GRAPHICS, &clock)); // current clock
  CHECK_NVML(nvmlDeviceGetClock(device, NVML_CLOCK_GRAPHICS, NVML_CLOCK_ID_CURRENT, &clock_current));
  CHECK_NVML(nvmlDeviceGetClock(device, NVML_CLOCK_GRAPHICS, NVML_CLOCK_ID_APP_CLOCK_TARGET, &clock_target));
  if(clock!=clock_current || clock_mem != clock_current_mem)
    std::cerr << ">> nvml current clock mismatch\n";
  int smi_id;
  std::vector<std::string>::const_iterator it = std::find(bus_ids.begin(), bus_ids.end(), std::string(pci.busId));
  if(it==bus_ids.end())
    smi_id = -1;
  else
    smi_id = it-bus_ids.begin();
  std::cout << dev << ": " << prop.name << "\n"
            << " GraphicsClock CUDA & NVML (target clock):   " << prop.clockRate/1000<< " & " << clock << " MHz" << "( @ " << clock_target << " MHz)"
            << "\n MemClock CUDA & NVML (target clock):        " << prop.memoryClockRate/1000 << " & " << clock_mem  << " MHz" << "( @ " << clock_target_mem << " MHz)"
            << "\n PCI-BUS ID:                                 " << pci.busId
            << "\n nvidia-smi ID (for flag '-i'):              " << smi_id
            << "\n";
}

int main() {
  //cuda_info();
  std::vector<std::string> bus_ids;
  std::cout << "--- ALL NVML/nvidia-smi Devices -----\n";
  nvml_info(bus_ids);
  std::cout << "--- Visible CUDA Devices -----\n";
  int ndevs = 0;
  CHECK_CUDA( cudaGetDeviceCount(&ndevs) );

  for(int i=0; i<ndevs; ++i) {
    //test_cuda_and_nvml_device(i);
    CHECK_CUDA(cudaSetDevice(i));
    CHECK_NVML( nvmlInit() );
    /**
     * cudaFree(0) forces context and clock setting initialization on GPU
     *
     * cudaSetDevice or cudaMalloc are not enough to apply clock settings.
     * If omitted, first kernel would start with different setting.
     * Also place this after nvmlInit() to get current clock settings.
     */
    CHECK_CUDA( cudaFree(0) );
    show_freqs(i, bus_ids);
    CHECK_NVML(nvmlShutdown());
  }

  return 0;
}
