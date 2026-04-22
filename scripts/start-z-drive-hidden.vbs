Option Explicit

Dim shell
Dim fileSystem
Dim scriptDirectory
Dim powerShellScript
Dim preferredPwsh
Dim command

Set shell = CreateObject("WScript.Shell")
Set fileSystem = CreateObject("Scripting.FileSystemObject")
scriptDirectory = fileSystem.GetParentFolderName(WScript.ScriptFullName)
powerShellScript = scriptDirectory & "\start-z-drive.ps1"
preferredPwsh = shell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Microsoft\WindowsApps\pwsh.exe"

If fileSystem.FileExists(preferredPwsh) Then
    command = """" & preferredPwsh & """ -NoLogo -NoProfile -ExecutionPolicy Bypass -File """ & powerShellScript & """"
Else
    command = "powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File """ & powerShellScript & """"
End If

shell.Run command, 0, False
