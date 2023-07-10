#Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.0.0"}

Describe 'Join-Object' {

    BeforeAll {

        Set-StrictMode -Version Latest

        . $PSScriptRoot\HiddenString.ps1

        $Secret = 'Confidential information'
    }

    Context 'General tests' {

        BeforeEach {

            $HiddenSecret = [HiddenString]$Secret
        }

        It 'Hide' {

            $HiddenSecret | Should -Be HiddenString
        }

        It 'Reveal' {

            $HiddenSecret.Reveal() | Should -Be $Secret
        }

        It 'Clear' {

            $HiddenSecret.Clear()
            $HiddenSecret.Reveal() | Should -BeNullOrEmpty
        }

        It 'Add' {

            $HiddenSecret = [HiddenString]::new()
            $HiddenSecret.Add($Secret)
            $HiddenSecret.Reveal() | Should -Be $Secret
        }

        It 'Equals' {

            $HiddenSecret -eq $HiddenSecret | Should -be $True
            $HiddenString = [HiddenString]'Something else'
            $HiddenSecret -eq $HiddenString | Should -be $False
        }

        It 'Length' {

            $HiddenSecret.Length | Should -be $Secret.Length
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

            $Actual | Should -Be $Secret
            Get-Content -Path $PSScriptRoot\Transcript.txt | Should -Not -Contain $Secret
        }

        It 'From base64 cypher' {

            $HiddenSecret = [HiddenString]$Secret
            if ($IsWindows) {
                $Cypher = $HiddenSecret.ToBase64Cypher()

                $HiddenSecret = [HiddenString][System.Convert]::FromBase64String($Cypher)
                $HiddenSecret.Reveal() | Should -Be $Secret

                $HiddenSecret = [HiddenString]::FromBase64Cypher($Cypher)
                $HiddenSecret.Reveal() | Should -Be $Secret
            }
            else {
                { $Cypher = $HiddenSecret.ToBase64Cypher() } | Should -Throw
            }
        }

        it 'Convert to SecureString' {
            
            $HiddenPassword = [HiddenString]$Secret
            $Credential = New-Object System.Management.Automation.PSCredential ('UserName', $HiddenPassword)
            $Password = ([HiddenString]$Credential.Password).Reveal()
            $Password | Should -Be $Secret
        }
    }
}
