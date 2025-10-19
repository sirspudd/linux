# Spudd kernel pruning record

Updated 2026-10-08. The target is a modern AMD desktop, an ASUS Zenbook S 16 with AMD laptop functionality, and a kernel that both hosts KVM virtual machines and runs inside them with accelerated graphics. `scx_bpfland` must continue to work.

The purpose of these removals is to reduce compilation, linking, debug-data generation, and build storage for functionality outside that target. Removing an unloaded module generally does not make the running desktop faster. Removing built-in code can also reduce the kernel image and its memory footprint.

The baseline is commit `556125d8ced5e5c93bd361a7df22d062a622061a`. All entries below describe the current [desktop preset](../arch/x86/configs/spudd_desktop_defconfig), including the networking edits pending when this record was created. Changes are cumulative; there is no assumption that every removed feature was obsolete or unsafe.

## Exact inventory

[kernel-pruning-symbols.tsv](kernel-pruning-symbols.tsv) records every configuration difference after expanding both the baseline and current presets against the current source tree with the same LLVM toolchain. It includes the previous value, current value, and whether the symbol was explicitly selected in each preset. `n` means disabled.

The resolved module count falls from **6,183 to 5,811**, a reduction of **372**. Across built-in and module options, **507 previously enabled symbols are now disabled**. These include dependent drivers and helpers, not 507 independent functional subsystems. Counts do not measure compilation time or bytes saved. The inventory is a snapshot; regenerate it when making further changes.

## Graphics and accelerator removals

| Removed support | Main configuration symbols | Reason | Restore when |
| --- | --- | --- | --- |
| Intel integrated and discrete graphics | `DRM_I915`, `DRM_XE`, their graphics security/MEI helpers, GVT-g, `XE_VFIO_PCI` | Target systems use AMD graphics. These are substantial driver families. | Using Intel graphics, an Intel display output, Intel GPU compute, or Intel GPU virtualization. |
| NVIDIA open graphics driver | `DRM_NOUVEAU`, `DRM_NOUVEAU_SVM` | No NVIDIA graphics target. | Using Nouveau with an NVIDIA GPU. Proprietary external drivers have separate requirements. |
| Older Radeon driver | `DRM_RADEON`, `DRM_RADEON_USERPTR` | Modern AMD hardware uses AMDGPU. | Running pre-AMDGPU hardware or an older configuration that requires Radeon. |
| Early GCN support inside AMDGPU | `DRM_AMDGPU_SI`, `DRM_AMDGPU_CIK`, dependent `DRM_AMD_DC_SI` | Southern Islands and Sea Islands are outside the modern-only target. | Using first/second-generation GCN GPUs or affected older APUs. |
| AGP and chipset support | `AGP`, AMD64/Intel/SiS/VIA helpers, dependent Intel GTT support | Target GPUs use PCIe. | Supporting an AGP graphics system. |
| Intel GMA500 | `DRM_GMA500` | Old Intel graphics is outside the target. | Using hardware supported by this driver. |
| Dedicated embedded display drivers | AUO A030JTN01, ILI9341, OTA5601A, WS2401, Raspberry Pi touchscreen, ST7571/ST7586/ST7735R/ST7920, SSD130x, MIPI DBI panels, Pixpaper, `TINYDRM_*` selections | These control particular embedded LCD/OLED/e-paper devices, not the AMD laptop's normal display. | Attaching one of those panels or display boards. |
| Legacy LCD framework and its drivers | `LCD_CLASS_DEVICE`, selected `LCD_*` devices, dependent picoLCD LCD controls | Not needed for the target's AMD-controlled laptop display. Backlight support remains. | Using one of those dedicated LCD devices. |
| Unrelated AI accelerators | `DRM_ACCEL_HABANALABS`, `HL_HLDIO`, `DRM_ACCEL_IVPU`, `DRM_ACCEL_QAIC` | No Habana, Intel NPU, or Qualcomm Cloud AI target. | Adding the corresponding accelerator hardware. |

Dependencies also remove unused DRM DMA framebuffer and MIPI DBI helpers. Modern AMD Display Core, its floating-point support, AMD ISP camera support, AMD ACP audio, AMD KFD/HSA compute, and AMD XDNA/Ryzen AI support remain enabled. VM graphics drivers, SimpleDRM, framebuffer console, KVM, and VFIO remain enabled.

The earlier removal of the explicit `SND_SOC_TAS2783_SDW` line did **not** disable that driver: it is still selected in the resolved configuration. Explicit preset deletions must always be checked against the generated `.config`. The subsequent graphics and networking pruning preserved the resolved audio configuration.

## Filesystem and Ceph removals

| Removed support | Main configuration symbols | Reason | Restore when |
| --- | --- | --- | --- |
| F2FS | `F2FS_FS` and its security/compression/checking options | No F2FS volume requirement. | Mounting an F2FS disk or image. |
| JFS | `JFS_FS`, ACL/security/statistics options | No JFS volume requirement. | Mounting JFS. |
| Old NTFS implementation | `NTFS_FS`, `NTFS_DEBUG`, `NTFS_FS_POSIX_ACL` | Retain the newer NTFS3 implementation instead of compiling both. | A specific workload requires the old driver. Existing mounts requesting `ntfs` may need to request `ntfs3` instead. |
| Shared-storage cluster filesystems | `GFS2_FS`, `GFS2_FS_LOCKING_DLM`, `OCFS2_FS`, `DLM`, `DLM_DEBUG` | No shared-storage cluster target. | Mounting GFS2/OCFS2 or requiring distributed lock management. |
| OrangeFS | `ORANGEFS_FS` | No OrangeFS cluster requirement. | Mounting OrangeFS. |
| Ceph filesystem and block devices | `CEPH_FS`, `BLK_DEV_RBD`, shared `CEPH_LIB` and its settings | Neither CephFS mounts nor Ceph-backed disks are required. | Mounting CephFS or mapping RBD disks, including VM disks. Restore the appropriate client, not necessarily both. |
| Coda | `CODA_FS` | No Coda distributed filesystem requirement. | Using a Coda client. |
| Apple filesystem compatibility | `HFS_FS`, `HFSPLUS_FS` | No HFS/HFS+ disk requirement. | Reading Apple-format disks or images using these formats. |
| Stacked directory encryption | `ECRYPT_FS` | No existing eCryptfs encrypted directory requirement. | Accessing eCryptfs data. LUKS/dm-crypt and fscrypt are separate facilities. |
| Specialized disk formats | `MINIX_FS`, `UFS_FS`, `AFFS_FS`, `BEFS_FS`, `OMFS_FS` | No MINIX, BSD UFS, Amiga, BeOS-family, Rio Karma, or ReplayTV disk requirement. | Mounting those disks or emulator images. |

XFS, Btrfs, ext4, NTFS3, FAT/exFAT, FUSE, OverlayFS, SquashFS, EROFS, NFS client/server, ordinary SMB client/server, and virtio filesystem support remain. JFFS2, UBIFS, NILFS2, AFS, and 9P were discussed as possible cuts but remain enabled.

## Specialized networking removals

Ordinary Ethernet, Wi-Fi, Bluetooth, IPv4/IPv6, packet and Unix sockets, firewall/NAT support, TUN/TAP, bridges, virtio networking, vhost networking, and the existing container interfaces remain. Physical Ethernet and Wi-Fi vendor families have not been broadly pruned.

| Removed family | Main configuration symbols | Reason | Restore when |
| --- | --- | --- | --- |
| InfiniBand and RDMA | `INFINIBAND`, its hardware and userspace drivers, `RDMA_RXE`, `RDMA_SIW`, `CGROUP_RDMA`, `SECURITY_INFINIBAND` | No RDMA networking requirement. This removes both hardware RDMA and software RDMA transports. | Using RDMA applications, InfiniBand/RoCE/iWARP, or a dependent storage transport. |
| RDMA storage and file transports | `NVME_RDMA`, `NVME_TARGET_RDMA`, RNBD client/server, iSER/SRP and RDMA-related helpers, `NET_9P_RDMA`, `SUNRPC_XPRT_RDMA`, `CIFS_SMB_DIRECT`, `SMB_SERVER_SMBDIRECT`, `MLX5_CORE_IPOIB` | No storage/file access over RDMA. Ordinary NVMe, TCP/IP networking, SMB, NFS, and non-RDMA 9P remain. | Using NVMe over RDMA, SMB Direct, NFS over RDMA, or the corresponding RDMA storage services. |
| Managed Ethernet switches | `NET_DSA` and selected switch/tagging drivers | No directly managed switch-chip hardware target. A normal Ethernet NIC and a Linux software bridge do not require DSA. | Using supported embedded/industrial switch hardware. |
| CAN buses | `CAN` and its protocols/controllers, CAN traffic-control match | No automotive or industrial CAN requirement. | Using SocketCAN, USB CAN adapters, or virtual CAN development. |
| Low-power wireless networking | `IEEE802154`, `6LOWPAN`, controllers, compression helpers, `BT_6LOWPAN` | No IEEE 802.15.4 or 6LoWPAN requirement. Ordinary Bluetooth remains. | Using supported sensor networking or IPv6 over low-power radio/Bluetooth. |
| NFC | `NFC` and its controller/protocol drivers | No NFC requirement. | Using NFC readers or integrated NFC hardware. |
| ATM and DSL transports | `ATM`, controller drivers, USB ATM/DSL devices | No ATM networking or these DSL devices. | Using affected modem/ATM hardware. |
| Phonet | `PHONET`, USB CDC Phonet and gadget components | No Phonet phone/modem networking. | Using compatible devices or Nokia USB gadget configurations. |
| Cluster/server transports | `TIPC`, `RDS`, `SMC`, `DIBS`, their diagnostics and media options | No applications requiring these transports. Ordinary TCP/UDP remain. | Using software that explicitly requires them. |
| Mesh routing | `BATMAN_ADV` and its dependent options | No batman-adv mesh network. | Joining or creating such a mesh. |
| Kernel load balancing | `IP_VS`, schedulers, helpers, iptables IPVS match | No IPVS service/load-balancing requirement. | Using IPVS load balancing or Kubernetes configured with IPVS. |

Turning off these parents also disables dependency-only Ethernet features: switchdev, data-center bridging, some specialized switch NIC drivers, Mellanox steering/bridge extras, and selected MDIO/PHY helpers. They are listed individually in the inventory. This is not a blanket removal of Mellanox, Intel, Broadcom, or other ordinary Ethernet drivers.

The networking pass reduces the resolved module count from **6,097 to 5,811**, removing **286 module selections**. These are configuration counts, not timed savings.

## Other removed dependency settings

The baseline comparison also removes `MTD_INTEL_DG`, Intel graphics-related MEI components, `HDMI_LPE_AUDIO`, and the dependent helper symbols listed in the inventory. They accompanied removal of Intel graphics or their now-unused consumers. `HDMI_LPE_AUDIO` is distinct from the HDA controller and AMD HDMI audio support retained for the laptop.

## Debugging and symbol export decisions

| Setting | Current decision | Consequence and reason to revisit |
| --- | --- | --- |
| `DEBUG_INFO_BTF_MODULES` | Disabled | Avoid BTF processing for every module. Kernel BTF remains for bpfland. Restore for tracing or BPF use that requires module type information. Module DWARF is still generated. |
| `DEBUG_INFO_DWARF5`, `DEBUG_INFO_BTF` | Retained | DWARF supplies input for kernel BTF; bpfland requires kernel BTF. Do not disable all debug information to shorten the build. |
| Debug-section compression | `DEBUG_INFO_COMPRESSED_ZSTD=y` | The temporary switch to uncompressed debug sections was not retained. Faster builds were not demonstrated; uncompressed sections increase storage and I/O. |
| `TRIM_UNUSED_KSYMS` | Enabled after the baseline | Drops exports without selected in-tree users. This can break future DKMS/external modules with missing symbols. Disable it or deliberately whitelist required symbols when using external modules. See [module Kconfig](../kernel/module/Kconfig). |
| CFI | Enabled after the baseline | Adds hardening rather than removing functionality. Resolved settings also enable integer-type normalization and x86 FineIBT support. It does not replace memory-error diagnostics or LSM policy enforcement. |
| KFENCE and other debug/tracing options | Retained | Suggested cuts were not applied. KFENCE remains a low-cost sampled memory-error detector. |
| SELinux and AppArmor | Still compiled | They were discussed but not removed. The default `LSM` list omits them; Landlock, lockdown, Yama, integrity, and BPF remain selected. |

## Compatibility to verify before broad deployment

On the desktop and Zenbook, verify graphical boot, suspend/resume, brightness, internal speakers/microphone, HDMI/DP audio, camera, Wi-Fi, Bluetooth, USB4/docks, and removable disks. Inside a VM, verify virtio graphics acceleration, networking, storage, and shared filesystems. On the host, verify VM startup and guest NAT/bridged networking; verify GPU passthrough if used.

For a failure after pruning, identify the device or service first with `lspci -nnk`, `lsusb`, `ethtool -i <interface>`, `findmnt`, and the relevant kernel/service logs. Missing modules, unsupported filesystem types, and external-module missing-symbol errors are useful clues. A module not loaded during one session is not proof that it is unnecessary on another machine or with an unplugged peripheral.

## Restoring a removed family

The PKGBUILD regenerates `spudd_desktop_defconfig` on every build, so restoration must be saved into the preset rather than only the build directory's `.config`.

1. Consult the inventory for the old parent and child selections. Enable the parent and the actual drivers/transports required; enabling only the parent does not necessarily restore its former children.
2. Use a separate output directory to configure and review the restoration:

   ```sh
   restore_build=$(mktemp -d /tmp/spudd-restore.XXXXXX)
   make O="$restore_build" LLVM=1 LLVM_IAS=1 spudd_desktop_defconfig
   make O="$restore_build" LLVM=1 LLVM_IAS=1 menuconfig
   make O="$restore_build" LLVM=1 LLVM_IAS=1 savedefconfig
   diff -u arch/x86/configs/spudd_desktop_defconfig "$restore_build/defconfig"
   ```

3. Once the diff contains the intended restoration, copy `$restore_build/defconfig` to `arch/x86/configs/spudd_desktop_defconfig`. Regenerate the config and verify the expected symbols, then build and test the affected functionality.
4. Record the restoration and reason here, and refresh the inventory. Keep a known-working bootable kernel while testing changes.

The complete original preset can be retrieved without changing the working tree:

```sh
git show 556125d8ced5e5c93bd361a7df22d062a622061a:arch/x86/configs/spudd_desktop_defconfig \
  > /tmp/spudd-original.defconfig
```

Use it to recover former child selections rather than replacing the current preset wholesale.

To audit future changes with defaults and dependencies resolved, compare configurations generated against the same source tree and toolchain:

```sh
audit_build=$(mktemp -d /tmp/spudd-audit.XXXXXX)
git show 556125d8ced5e5c93bd361a7df22d062a622061a:arch/x86/configs/spudd_desktop_defconfig \
  > "$audit_build/baseline.config"
make O="$audit_build" LLVM=1 LLVM_IAS=1 KCONFIG_CONFIG="$audit_build/baseline.config" olddefconfig
make O="$audit_build" LLVM=1 LLVM_IAS=1 spudd_desktop_defconfig
scripts/diffconfig "$audit_build/baseline.config" "$audit_build/.config"
```

Use that resolved diff to update the inventory and the corresponding reason/restore condition above. Comparing only preset text can mistake an omitted default for disabled functionality.

## Build evidence

The `2026-10-08-1421.log` build completed in **10 minutes 23.607 seconds**, with **19,750 C compilation entries**, **6,270 module links**, and **zero module-BTF entries**. That build predates the specialized-networking removal. It is not a measurement of the current preset or a controlled comparison with the baseline.

The cumulative config changes have been checked by generating configurations with LLVM. Configuration checks establish dependency resolution; hardware testing and comparable timed builds establish compatibility and actual savings.
