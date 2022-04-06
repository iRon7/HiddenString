class HiddenString {
    hidden [SecureString]$SecureString = [SecureString]::new()
    hidden [Bool]$SuppressWarnings
    
    hidden New([Object]$Object, [Bool]$SuppressWarnings) {
        $This.SuppressWarnings = $SuppressWarnings
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
        elseif ($Object) {
            if (!$This.SuppressWarnings) { Write-Warning 'For better obscurity, use a hidden or secure string for input.' }
            $This.Add($Object)
        }
    }
    HiddenString()                                   { $This.New($Null,   $False) }
    HiddenString([Object]$Object)                    { $This.New($Object, $False) }
    HiddenString([Object]$Object, $SuppressWarnings) { $This.New($Object, $SuppressWarnings) }
    static [HiddenString]FromBase64Cypher([string]$String) { return [System.Convert]::FromBase64String($String) }

    [Void]Clear() { $This.SecureString.Clear() }
    [Void]Add([Char[]]$Characters) { $Characters.ForEach{ $This.SecureString.AppendChar($_) } }
    [Bool]Equals($Object) { return $This.SecureString.Equals($Object.SecureString) }
    [SecureString]ToSecureString() { return $This.SecureString }
    [String]Reveal(){
        if (!$This.SuppressWarnings) { Write-Warning 'For better obscurity, use a secure string output.' }
        $Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($This.SecureString)
        $String = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemUnicode($Ptr)
        return $String
    }
}