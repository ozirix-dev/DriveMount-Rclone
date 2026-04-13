Option Explicit

Dim shell
Dim scriptDirectory
Dim powerShellScript
Dim command

Set shell = CreateObject("WScript.Shell")
scriptDirectory = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
powerShellScript = scriptDirectory & "\start-z-drive.ps1"

command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & powerShellScript & """"
shell.Run command, 0, False
