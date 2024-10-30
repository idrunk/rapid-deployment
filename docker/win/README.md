## Docker desktop

### WSL 2 backend
- WSL version 1.1.3.0 or later.
- Windows 11 64-bit: Home or Pro version 21H2 or higher, or Enterprise or Education version 21H2 or higher.
- Windows 10 64-bit:
    - We recommend Home or Pro 22H2 (build 19045) or higher, or Enterprise or Education 22H2 (build 19045) or higher.
    - Minimum required is Home or Pro 21H2 (build 19044) or higher, or Enterprise or Education 21H2 (build 19044) or higher.
- Turn on the WSL 2 feature on Windows. For detailed instructions, refer to the Microsoft documentation.
- The following hardware prerequisites are required to successfully run WSL 2 on Windows 10 or Windows 11:
    - 64-bit processor with Second Level Address Translation (SLAT)
    - 4GB system RAM
    - Enable hardware virtualization in BIOS. For more information, see Virtualization.

### Hyper-V backend, x86_64
- Windows 11 64-bit: Home or Pro version 21H2 or higher, or Enterprise or Education version 21H2 or higher.
- Windows 10 64-bit:
    - We recommend Home or Pro 22H2 (build 19045) or higher, or Enterprise or Education 22H2 (build 19045) or higher.
    - Minimum required is Home or Pro 21H2 (build 19044) or higher, or Enterprise or Education 21H2 (build 19044) or higher.
- Turn on Hyper-V and Containers Windows features.
- The following hardware prerequisites are required to successfully run Client Hyper-V on Windows 10:
    - 64 bit processor with Second Level Address Translation (SLAT)
    - 4GB system RAM
    - Turn on BIOS-level hardware virtualization support in the BIOS settings. For more information, see Virtualization.


## Windows wsl2

### Manual installation steps for older versions of WSL
1. Step 1 - Enable the Windows Subsystem for Linux
2. Step 2 - Check requirements for running WSL 2
    For windows 10:
    - For x64 systems: Version 1903 or later, with Build 18362.1049 or later.
    - For ARM64 systems: Version 2004 or later, with Build 19041 or later.
3. Step 3 - Enable Virtual Machine feature
4. Step 4 - Download the Linux kernel update package
    > wsl_update_x64.msi
5. Step 5 - Set WSL 2 as your default version
    `wsl --set-default-version 2`
6. Step 6 - Install your Linux distribution of choice
