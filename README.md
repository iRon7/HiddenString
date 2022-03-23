# HiddenString Class
Hides sensitive information from other identities including the console and log files.

### Scripting secrets dilemma
You have been asked to build an unattended script that securely handles confidential information (e.g. a password) supplied by a process or a system (e.g. a System Management system) and required by another process or system (e.g. a website). The catch in this request is often if either the input system provides the information in plaintext or output system to output to expects the information in plaintext format, you will never succeed. In fact, the information should already be secured prior it enters the script and should never be revealed but passed on to the system at the other end. In other words, the script actually shouldn’t do anything with the confidential information and actually should be left out this debacle.  
Avoid using the (optional) plaintext password parameter for the [`Set-ScheduledTask`](https://docs.microsoft.com/powershell/module/scheduledtasks/set-scheduledtask) and instead allow the account that runs the script to create ScheduledTasks.
This is in line with the .Net communitie [**`SecureString` shouldn't be used** statement](https://github.com/dotnet/platform-compat/blob/master/docs/DE0001.md):

> The general approach of dealing with credentials is to avoid them and instead rely on other means to authenticate, such as certificates or Windows authentication.

Which leaves scripters with a similar dilemma (besides that [certain `SecureString APIs` will be obsolete](https://github.com/dotnet/designs/pull/147)): a `SecureString` is quiet safe by itself as long as you don’t reveal what is in it, and according to the [SecureString operations](https://docs.microsoft.com/dotnet/api/system.security.securestring#securestring-operations):

> ⚠️ **Important**
>
> A **SecureString** object should never be constructed from a **String**, because the sensitive data is already subject to the memory persistence consequences of the immutable **String** class. The best way to construct a **SecureString** object is from a character-at-a-time unmanaged source, such as the **Console.ReadKey** method.

<sub>("Such as the **Console.ReadKey** method" means: [`Read-Host -AsSecureString`](https://docs.microsoft.com/powershell/module/microsoft.powershell.utility/read-host) in PowerShell)</sub>

This makes a `SecureString` virtually useless for its "secure" intention such as an unattended script that needs to handle secrets provided and required as plaintext and difficult to use for less secure (but sensitive) information (e.g. an embedded API key) as it doesn't provide easy string convertors as it is a security risk.

A `HiddenString`, on the contrary, is less secure *by its definition* but therefore able to provide easier string conversions allowing for better and easier obscuring confidential information right at the in- and output boundaries of a PowerShell script where "*certificates or Windows authentication*" can't be implemented overnight or it concerns sensitive (private) information.

## Examples
The following example demonstrates how to use a HiddenString to hide a user's password provided by an input process and required by an output process.

```PowerShell
function RegisterTask([String]$TaskName, [String]$Action, [String]$UserName, [HiddenString]$Password) {
    Write-Host "Scheduling $TaskName for $UserName/$Password" # Write-Log ...
    Register-ScheduledTask -TaskName $TaskName -Action $Action -User "user" -Password "password"
}

Start-Transcript -Path $PSScriptRoot\Transcript.txt
RegisterTask Test NotePad.Exe JohnDoe $Password
Stop-Transcript
```
