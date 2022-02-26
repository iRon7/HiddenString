class HiddenString {
    hidden [SecureString]$SecureString = [SecureString]::new()
    HiddenString([Object]$String) {
        if ($String -is [SecureString]) { $This.SecureString = $String }
        else {
            foreach ($Character in [Char[]]$String) { $This.SecureString.AppendChar($Character) }
        }
    }
    [String]Reveal(){
        $Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($This.SecureString)
        $String = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemUnicode($Ptr)
        Return $String
    }
}

$HiddenString = [HiddenString]'Password'
$HiddenString.Reveal()

