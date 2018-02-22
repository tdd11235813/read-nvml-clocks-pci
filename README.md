# read-nvml-clocks-pci

Reads GPU Current and Target Clocks as well as nvidia-smi compatible PCIe BUS ID.
nvidia-smi uses PCI ordering while `CUDA_VISIBLE_DEVICES` might not.
This also helps to find the affinity by e.g. `nvidia-smi topo -m` and `numactl -H`.
Job based GPU/CPU pinning might happen via minor number (`nvidia-smi -q | grep Minor`), 
which does not have to be the same order as PCI id.

## Example

```bash
> ./read-nvml-clocks-pci
--- ALL NVML/nvidia-smi Devices -----
0: Dev Name, Tesla K80, PCI Bus (domain:bus:dev), 00000000:04:00.0, PCI Bus, 4, PCI Domain, 0, PCI Dev, 0, PCI DevID, 271388894, PCI SubsysID, 275517662
1: Dev Name, Tesla K80, PCI Bus (domain:bus:dev), 00000000:05:00.0, PCI Bus, 5, PCI Domain, 0, PCI Dev, 0, PCI DevID, 271388894, PCI SubsysID, 275517662
2: Dev Name, Tesla K80, PCI Bus (domain:bus:dev), 00000000:84:00.0, PCI Bus, 132, PCI Domain, 0, PCI Dev, 0, PCI DevID, 271388894, PCI SubsysID, 275517662
3: Dev Name, Tesla K80, PCI Bus (domain:bus:dev), 00000000:85:00.0, PCI Bus, 133, PCI Domain, 0, PCI Dev, 0, PCI DevID, 271388894, PCI SubsysID, 275517662
--- Visible CUDA Devices -----
0: Tesla K80
 GraphicsClock CUDA & NVML (target clock):   823 & 823 MHz( @ 823 MHz)
 MemClock CUDA & NVML (target clock):        2505 & 2505 MHz( @ 2505 MHz)
 PCI-BUS ID:                                 00000000:04:00.0
 nvidia-smi ID (for flag '-i'):              0
1: Tesla K80
 GraphicsClock CUDA & NVML (target clock):   823 & 823 MHz( @ 823 MHz)
 MemClock CUDA & NVML (target clock):        2505 & 2505 MHz( @ 2505 MHz)
 PCI-BUS ID:                                 00000000:05:00.0
 nvidia-smi ID (for flag '-i'):              1
```


