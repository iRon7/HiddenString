# HiddenString Class
Hides sensitive information from other identities including the console and log files.

### Scripting secrets dilemma
You have been asked to build an unattended script that securely handles confidential information (e.g. a password) supplied by a process or a system (e.g. a System Management system) and required by another process or system (e.g. a website). The catch in this request is often if either the input system provides the information in plaintext or output system to output to expects the information in plaintext format, you will never succeed. In fact, the information should already be secured prior it enters the script and should never be revealed but passed on to the system at the other end. In other words, the script actually shouldn’t do anything with the confidential information and actually should be left out this debacle.  
Avoid using the (optional) plaintext password parameter for the [`Set-ScheduledTask`](https://docs.microsoft.com/powershell/module/scheduledtasks/set-scheduledtask) and instead allow the account that runs the script to create ScheduledTasks.
This is in line with the .Net communitie [**`SecureString` shouldn't be used** statement](https://github.com/dotnet/platform-compat/blob/master/docs/DE0001.md):

> The general approach of dealing with credentials is to avoid them and instead rely on other means to authenticate, such as certificates or Windows authentication.

Which leaves scripters with a similar dilemma (besides that [certain `SecureString APIs` will be obsolete](https://github.com/dotnet/designs/pull/147)¹): a `SecureString` is quiet safe by itself as long as you don’t reveal what is in it, and according to the [SecureString operations](https://docs.microsoft.com/dotnet/api/system.security.securestring#securestring-operations):

> ⚠️ **Important**
>
> A **SecureString** object should never be constructed from a **String**, because the sensitive data is already subject to the memory persistence consequences of the immutable **String** class. The best way to construct a **SecureString** object is from a character-at-a-time unmanaged source, such as the **Console.ReadKey** method.

<sub>("Such as the **Console.ReadKey** method" means: [`Read-Host -AsSecureString`](https://docs.microsoft.com/powershell/module/microsoft.powershell.utility/read-host) in PowerShell)</sub>

This makes a `SecureString` virtually useless for its "secure" intention such as an unattended script that needs to handle secrets provided and required as plaintext and difficult to use for less secure (but sensitive) information (e.g. an embedded API key) as it doesn't provide easy string convertors as it is a security risk.

A `HiddenString`, on the contrary, is less secure *by its definition* but therefore able to provide easier string conversions allowing for better and easier obscuring confidential information right at the in- and output boundaries of a PowerShell script where "*certificates or Windows authentication*" can't be implemented overnight or it concerns sensitive (private) information.

Another difference with a `SecureString` is that *user* (rather than the *developer*) is automatically warned when the obscurity of the concerned string might be compromised.

1) The intent is to replace the internal `SecureString` class when it is complete depleted and replaced with a solution with simular functionalities.

## Examples
### Handling plain text secrets from other applications
The following example demonstrates how to use a `HiddenString` to hide plain text password provided by software management system and required by an application.

```PowerShell
function RegisterTask {
    [CmdletBinding()] param(
        [String]$TaskName,
        [String]$Action,
        [String]$Username,
        [HiddenString]$HiddenPassword
    )
    Write-Host "Scheduling $Action for $Username/$HiddenPassword" # Write-Log ...
    $TaskAction = New-ScheduledTaskAction -Execute $Action
    Register-ScheduledTask -TaskName $TaskName -Action $TaskAction -User $Username -Password $HiddenPassword.Reveal()
}

PS C:\> $Password = 'Unsecure plain text password'
PS C:\> Start-Transcript -Path .\Transcript.txt
Transcript started, output file is .\Transcript.txt
PS C:\> RegisterTask Test NotePad.Exe JohnDoe $Password
WARNING: For better obscurity, use a hidden or secure string for input.
Scheduling NotePad.Exe for JohnDoe/HiddenString
WARNING: For better obscurity, use a secure string output.
PS C:\> Stop-Transcript
Transcript stopped, output file is .\Transcript.txt
```

#### Suppressing warnings 
To prevent the input string warning, use a `HiddenString` by using the `new` contructor with an additional `$True` .Net parameter.  
To prevent the output string warning, use the common [`-WarningAction SilentlyContinue`](https://docs.microsoft.com/powershell/module/microsoft.powershell.core/about/about_commonparameters#-warningaction) PowerShell parameter:

```PowerShell
$Password = [HiddenString]::new('Unsecure plain text password', $False)
RegisterTask Test NotePad.Exe JohnDoe $Password -WarningAction SilentlyContinue
```

### Embedding confidential information
To embed confidential information in a script (e.g. an symmetric api key to publish software) you might use an [Base64](https://en.wikipedia.org/wiki/Base64) encrypted string which can only be decrypted by the account that created the Base64 cyphertext. This will prefent that the information might be easially revealed to other accounts.

To created the Base64 cyphertext string:
```PowerShell
PS C:\> $Cypher = ([HiddenString](Read-Host -Prompt 'Enter your password' -AsSecureString)).ToBase64Cypher()
PS C:\> Write-Host 'Cypher:' $Cypher
AQAAANCMnd8BFdERjHoAwE/Cl+sBAAAAVNHJrsxJcEyIKLld+U44qAAAAAACAAAAAAAQZgAAAAEAACAAAADqwdt1qzSssx5XE2hpZvh5oCa+BIeVFxdr7Vh+WZD3agAAAAAOgAAAAAIAACAAAADX9hdq/I+w5SBhSQ3/odPZKivZFLz9k+6TWqfvWyfEJkAAAAAc7hal4f9BoPLGtlQOc1uqKYKN9q6+3UYD9p2N5WgIrLKXtHNILjFhQ3kKGWxwQ3h5q8nf2e5fL1ndGfozJhrgQAAAAE3K+DiW3fWi2zwhRfuwLMJjeQDbmCBVaAxhe9BAZZgqmnu/mWy6vBC9DSXPmVDSl06kQ13iRon7+1963/10/07=
```

Copy the Base64 string (`$Base64 |Clip`) and paste it in the publishing script, like:

```PowerShell
$Cypher = 'AQAAANCMnd8BFdERjHoAwE/Cl+sBAAAAVNHJrsxJcEyIKLld+U44qAAAAAACAAAAAAAQZgAAAAEAACAAAADqwdt1qzSssx5XE2hpZvh5oCa+BIeVFxdr7Vh+WZD3agAAAAAOgAAAAAIAACAAAADX9hdq/I+w5SBhSQ3/odPZKivZFLz9k+6TWqfvWyfEJkAAAAAc7hal4f9BoPLGtlQOc1uqKYKN9q6+3UYD9p2N5WgIrLKXtHNILjFhQ3kKGWxwQ3h5q8nf2e5fL1ndGfozJhrgQAAAAE3K+DiW3fWi2zwhRfuwLMJjeQDbmCBVaAxhe9BAZZgqmnu/mWy6vBC9DSXPmVDSl06kQ13iRon7+1963/10/07='
$HiddenKey = [HiddenString]::FromBase64Cypher($Cypher))
Publish-Script -Path .\MyScript.ps1 -NuGetApiKey $HiddenKey.Reveal() -Verbose
```

### Secure string conversions
The `HiddenString` has a seamless conversion *from* a `SecureString` and *to* a `SecureString`:

```PowerShell
PS C:\> $HiddenPassword = [HiddenString](Read-Host -Prompt 'Enter your password' -AsSecureString)
PS C:\> $Credential = New-Object System.Management.Automation.PSCredential ('UserName', $HiddenPassword)
PS C:\> $Password = ([HiddenString]$Credential.Password).Reveal()
WARNING: For better obscurity, use a secure string output.
```

## Constructors

#### `HiddenString()`
Initializes a new instance of the `HiddenString` class.

#### `HiddenString(char[])`
Initializes a new instance of the `HiddenString` class from a subarray of `Char` objects.

#### `HiddenString(char[], bool)`
Initializes a new instance of the `HiddenString` class from a subarray of `Char` objects and enables the convert from string warning.

## Properties
All  `HiddenString` class properties are hidden so that the default (PowerShell) output is `HiddenString`.

#### `SecureString`	
Gets the embedded secure string.

#### `Length`	
Gets the number of characters in the current hidden string.

## Methods

#### `Add(char[])`	
Adds one or more characters to the end of the current hidden string.

#### `Add(char[], bool)`	
Adds one or more characters to the end of the current hidden string and enables the convert from string (multiple character) warning.

#### `Clear()`
Deletes the value of the current hidden string.

#### `Equals(Object)`
Determines whether the specified object is equal to the current object. (Inherited from Object)

#### `GetBytes()`
Gets the encrypted bytes array.

#### `ToBase64Cypher()`
Gets the Base64 Cypher string.

#### `Reveal()`
Reveals the plain text string from the hidden string.

#### `Reveal(bool)`
Reveals the plain text string from the hidden string and enables the convert to string warning.

#### `Dispose()`
Releases all resources used by the current `HiddenString` object.
