#Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.0.0"}

Describe 'Join-Object' {

    BeforeAll {

        Set-StrictMode -Version Latest

        . $PSScriptRoot\HiddenString.ps1

        $Secret = 'Confidential information'
    }

    Context 'General tests' {

        BeforeAll {

            $HiddenSecret = [HiddenString]$Secret
        }

        It 'Hide' {

            $HiddenSecret |Should -Be HiddenString
        }

        It 'Reveal' {

            $HiddenSecret.Reveal() |Should -Be $Secret
        }

        It 'Clear' {

            $HiddenSecret.Clear()
            $HiddenSecret.Reveal() |Should -BeNullOrEmpty
        }

        It 'Add' {

            $HiddenSecret.Add($Secret)
            $HiddenSecret.Reveal() |Should -Be $Secret
        }

        It 'Equals' {

            $HiddenSecret -eq $HiddenSecret |Should -be $True
            $HiddenString = [HiddenString]'Something else'
            $HiddenSecret -eq $HiddenString |Should -be $False
        }
    }

    Context 'Use cases' {

        It 'Hidden parameter' {

            $Actual = $Null

            function BadApp([String]$Username, [String]$Password) {
                ([ref]$Actual).Value = $Password
            }

            function MyScript {
                [CmdletBinding()] param(
                    [String]$Username,
                    [HiddenString]$Password
                )
                Write-Host "Credentials: $Username/$Password" # Write-Log ...
                BadApp $Username $Password.Reveal()
            }
            Start-Transcript -Path $PSScriptRoot\Transcript.txt
            MyScript JohnDoe $Secret -WarningAction SilentlyContinue
            Stop-Transcript

            $Actual |Should -Be $Secret
            Get-Content -Path $PSScriptRoot\Transcript.txt |Should -Not -Contain $Secret
        }

        It 'From base64 string' {

            $SecureString = [SecureString]::new()
            ([Char[]]$Secret).ForEach{ $SecureString.AppendChar($_) }
            $Base64 = [Convert]::ToBase64String(([regex]::matches(($SecureString |ConvertFrom-SecureString), '.{2}')).foreach{ [byte]"0x$_" })

            $HiddenSecret = [HiddenString]::New([System.Convert]::FromBase64String($Base64))
            $HiddenSecret.Reveal() |Should -Be $Secret

            $HiddenSecret = [HiddenString]::FromBase64Cypher($Base64)
            $HiddenSecret.Reveal() |Should -Be $Secret
        }

        it 'Convert to SecureString' {
            
            $Password = [HiddenString]$Secret
            $PSCredential = New-Object System.Management.Automation.PSCredential ('UserName', $Password)
            
        }
    }
}
