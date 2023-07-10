<#PSScriptInfo
.VERSION 0.0.2
.GUID 19631007-fc1e-4466-a274-624cb5f246dc
.AUTHOR iRon
.COMPANYNAME
.COPYRIGHT
.TAGS Hidden String Secure Hide Secret
.LICENSE https://github.com/iRon7/HiddenString/LICENSE
.PROJECTURI https://github.com/iRon7/HiddenString
.ICON
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
.PRIVATEDATA
#>

class HiddenString {
    hidden static $DPAPI # https://en.wikipedia.org/wiki/Data_Protection_API
    hidden [SecureString]$SecureString = [SecureString]::new()
    hidden $_Length = $($this | Add-Member ScriptProperty 'Length' { $This.SecureString.Length })

    hidden New([Object]$Object, [Bool]$Warn) {
        if ($Object -is [SecureString]) { $This.SecureString = $Object }
        elseif ($Object -is [HiddenString]) { $This.SecureString = $Object.SecureString }
        elseif ($Object -is [Byte[]]) {
            $String = [System.Text.StringBuilder]::new()
            foreach ($Byte in $Object) {
                $x2 = '{0:x2}' -f $Byte
                [void]$String.Append($x2)
            }
            $This.SecureString = ConvertTo-SecureString $String
        }
        elseif ($Object) { $This.Add($Object, $Warn) }
    }
    HiddenString()                       { $This.New($Null,   $True) }
    HiddenString([Object]$Object)        { $This.New($Object, $True) }
    HiddenString([Object]$Object, $Warn) { $This.New($Object, $Warn) }
    static [HiddenString]FromBase64Cypher([string]$String) { return [System.Convert]::FromBase64String($String) }

    [Void]Clear() { $This.SecureString.Clear() }
    [Void]Add([Char[]]$Characters) { $This.Add($Characters, $True) }
    [Void]Add([Char[]]$Characters, [bool]$Warn) {
        if ($Warn -and $Characters.Count -gt 1) { Write-Warning 'For better obscurity, use a hidden or secure string for input.' }
        $Characters.ForEach{ $This.SecureString.AppendChar($_) }
    }
    [Bool]Equals($Object) { return $This.SecureString.Equals($Object.SecureString)}
    [SecureString]ToSecureString() { return $This.SecureString }
    [Byte[]]GetBytes() {
        if ($Null -eq [HiddenString]::DPAPI) {
            [HiddenString]::DPAPI = ('@' | ConvertTo-SecureString -AsPlainText | ConvertFrom-SecureString).Length -gt 100
        }
        if (![HiddenString]::DPAPI) { Throw "The operating system doesn't support DPAPI encryption." }
        $Hexadecimal = $This.SecureString |ConvertFrom-SecureString
        return ([regex]::matches($Hexadecimal, '.{2}')).foreach{ [byte][Convert]::ToInt64($_, 16) }
    }
    [String]ToBase64Cypher() { return [Convert]::ToBase64String($This.GetBytes()) }
    [String]Reveal() { return $This.Reveal($True) }
    [String]Reveal($Warn) {
        if ($Warn) { Write-Warning 'For better obscurity, use a secure string output.' }
        $Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($This.SecureString)
        $String = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemUnicode($Ptr)
        return $String
    }
    [Void]Dispose() { $This.SecureString.Dispose() }
}

class HiddenStringConverter : System.Management.Automation.PSTypeConverter
{
    [bool] CanConvertFrom([object]$sourceValue, [Type]$destinationType) {
        return $false
    }
    [object] ConvertFrom([object]$sourceValue, [Type]$destinationType, [IFormatProvider]$formatProvider, [bool]$ignoreCase) {
        throw [NotImplementedException]::new() 
    }
    [bool] CanConvertTo([object]$sourceValue, [Type]$destinationType) {
        return $destinationType -eq [System.Security.SecureString] -or $destinationType -eq [byte[]]
    }
    [object] ConvertTo([object]$sourceValue, [Type]$destinationType, [IFormatProvider]$formatProvider, [bool]$ignoreCase) {
        if     ($destinationType -eq [System.Security.SecureString]) { return $sourceValue.SecureString }
        elseif ($destinationType -eq [byte[]]) { return $sourceValue.GetBytes() }
        else { throw [NotImplementedException]::new() }
    }
}
Remove-TypeData -TypeName HiddenString -ErrorAction SilentlyContinue
Update-TypeData -TypeName HiddenString -TypeConverter HiddenStringConverter
