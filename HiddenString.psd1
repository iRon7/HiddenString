@{
    ScriptsToProcess = @('HiddenString.ps1')
    ModuleVersion = '0.1.1'
    GUID = '56de5284-3332-4f60-a5c7-3bf18ec8ab1b'
    Author = 'Ronald Bode (iRon)'
    CompanyName = 'PowerSnippets'
    Copyright = '(c) iRon. All rights reserved.'
    Description = 'Hides sensitive information from other identities including the console and log files.'
    PowerShellVersion = '3.0'
    FunctionsToExport = @()
    CmdletsToExport = @()
    VariablesToExport = '*'
    PrivateData = @{
        PSData = @{
            Tags = 'Hide','Hidden','String','Encrypt','Decrypt','Secure'
            LicenseUri = 'https://github.com/iRon7/HiddenString/LICENSE'
            ProjectUri = 'https://github.com/iRon7/HiddenString'
            IconUri = ''
            ReleaseNotes = 'Prototype'
        }
    }
}