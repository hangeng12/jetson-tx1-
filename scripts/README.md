# Scripts

These scripts are helper scripts extracted from a real Jetson TX1 Ubuntu 18.04 to 20.04 upgrade.

They are not a one-click installer. Read the main docs before using them.

## Recommended Order

1. `00_sudo_test.sh`
   - Check current user and sudo availability.

2. `10_preflight_backup_and_hold_l4t.sh`
   - Capture system information.
   - Back up apt and boot metadata.
   - Hold all `nvidia-l4t-*` packages.

3. `11_prepare_apt_18_04.sh`
   - Repair and fully update the current Ubuntu 18.04 system.
   - Install release upgrade tools.

4. `20_run_release_upgrade.sh`
   - Run the interactive `do-release-upgrade` process.
   - Use a local console, serial console, or tmux/screen if possible.

5. `30_postupgrade_repair.sh`
   - Repair dpkg/apt state after the upgrade.
   - Clean up common Chromium-related conflicts if present.

6. `31_repair_appstream.sh`
   - Repair AppStream cache and apt hook issues.

7. `40_finalize_services_and_apt.sh`
   - Disable unnecessary failed DHCP server units if present.
   - Archive crash reports.
   - Verify services and apt/dpkg state.

8. `41_switch_apt_mirror_https.sh`
   - Optional.
   - Switch Ubuntu ports apt sources to a configurable HTTPS mirror.
   - Adds apt network settings for IPv4 and retries.

9. `50_post_reboot_verify.sh`
   - Run after reboot.
   - Verify OS, kernel, L4T, rootfs, services, apt/dpkg and GPIO nodes.

10. `60_dev_gpio_prep.sh`
    - Install common development and GPIO tools.
    - Add udev rules for `/dev/gpiochip*` access.

11. `70_install_chinese_ime.sh`
    - Optional.
    - Install IBus intelligent pinyin and Chinese fonts/language packs.

## Notes

- Keep `nvidia-l4t-*` packages held.
- Do not run multiple apt/dpkg commands at the same time.
- Use an SD card rootfs if possible.
- Keep a full image backup.
- This workflow is not officially supported by NVIDIA.

