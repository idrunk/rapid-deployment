### Sudo run on windows
compiled from: <https://github.com/microsoft/sudo>
reference: <https://winaero.com/sudo-for-windows-11-actually-runs-on-windows-10-and-windows-7/>

#### Process
1. Boot into Windows 11 Build 26052 and copy sudo.exe from c:\windows\system32 to some other location.
2. Boot into Windows 7 or Windows 10. Btw, Windows 8.1/8 will do the trick too.
3. Copy the sudo.exe file to c:\windows\system32 of Windows 10/8/7.
4. Open the Start menu, type cmd.exe and press Ctrl + Shift + Enter to open command prompt as Administrator.
5. Finally, type these two commands, one after one.
   ``` cmd
   sudo config --enable enable
   @rem Actually no need to execute this, it is better to run inline by default
   sudo config --enable forceNewWindow
   ```
