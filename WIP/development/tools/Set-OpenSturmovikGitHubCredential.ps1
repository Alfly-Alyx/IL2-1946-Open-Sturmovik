[CmdletBinding()]
param(
    [string]$Repository = 'Alfly-Alyx/IL2-1946-Open-Sturmovik',
    [string]$StateRoot = (Join-Path $env:LOCALAPPDATA 'OpenSturmovik\Diagnostics'),
    [Security.SecureString]$Token,
    [switch]$UseGitCredential,
    [switch]$Remove
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

if ($Repository -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') { throw "Depot GitHub invalide : $Repository" }
$state = [IO.Path]::GetFullPath($StateRoot)
$tokenPath = Join-Path $state 'github-token.dpapi'

if ($Remove) {
    Remove-Item -LiteralPath $tokenPath -Force -ErrorAction SilentlyContinue
    [pscustomobject]@{ Status = 'REMOVED'; Credential = $tokenPath }
    exit 0
}

$plainToken = $null
if ($UseGitCredential) {
    $git = Get-Command git.exe -ErrorAction SilentlyContinue
    if (-not $git) { $git = Get-Command git -ErrorAction SilentlyContinue }
    if (-not $git) { throw 'Git Credential Manager est indisponible.' }
    $credentialInputPath = [IO.Path]::GetTempFileName()
    try {
        [IO.File]::WriteAllText($credentialInputPath, "protocol=https`r`nhost=github.com`r`n`r`n", [Text.Encoding]::ASCII)
        $startInfo = New-Object Diagnostics.ProcessStartInfo
        $startInfo.FileName = $env:ComSpec
        $startInfo.Arguments = '/d /s /c ""' + $git.Source + '" credential fill < "' + $credentialInputPath + '""'
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true
        $credentialProcess = New-Object Diagnostics.Process
        $credentialProcess.StartInfo = $startInfo
        [void]$credentialProcess.Start()
        $credentialOutput = $credentialProcess.StandardOutput.ReadToEnd()
        $credentialProcess.StandardError.ReadToEnd() | Out-Null
        $credentialProcess.WaitForExit()
        if ($credentialProcess.ExitCode -ne 0) {
            throw "Git Credential Manager a refuse la demande (code $($credentialProcess.ExitCode))."
        }
    }
    finally {
        Remove-Item -LiteralPath $credentialInputPath -Force -ErrorAction SilentlyContinue
    }
    foreach ($line in @($credentialOutput -split '\r?\n')) {
        if ($line.StartsWith('password=', [StringComparison]::OrdinalIgnoreCase)) {
            $plainToken = $line.Substring('password='.Length)
            break
        }
    }
    if ([string]::IsNullOrWhiteSpace($plainToken)) { throw 'Git Credential Manager ne fournit aucun identifiant GitHub.' }
}
else {
    if ($null -eq $Token) {
        $Token = Read-Host 'Jeton GitHub autorise a creer des tickets dans le depot Open Sturmovik' -AsSecureString
    }
    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Token)
    try { $plainToken = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer) }
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$headers = @{
    Authorization = 'Bearer ' + $plainToken
    Accept = 'application/vnd.github+json'
    'X-GitHub-Api-Version' = '2022-11-28'
    'User-Agent' = 'Open-Sturmovik-Diagnostics-Setup'
}
try {
    $repositoryInfo = Invoke-RestMethod -Method Get -Uri ('https://api.github.com/repos/' + $Repository) -Headers $headers
    if (-not $repositoryInfo.has_issues) { throw "Les tickets GitHub sont desactives dans $Repository." }
    if (-not $UseGitCredential) {
        New-Item -ItemType Directory -Path $state -Force | Out-Null
        $Token | ConvertFrom-SecureString | Set-Content -LiteralPath $tokenPath -Encoding ASCII
    }
}
finally {
    $plainToken = $null
    Remove-Variable headers -ErrorAction SilentlyContinue
}

[pscustomobject]@{
    Status = 'AUTHENTICATION_VERIFIED'
    Repository = $Repository
    IssuesEnabled = [bool]$repositoryInfo.has_issues
    CredentialSource = if ($UseGitCredential) { 'GIT_CREDENTIAL_MANAGER' } else { 'DPAPI_CURRENT_USER' }
    Stored = [bool](-not $UseGitCredential)
}
