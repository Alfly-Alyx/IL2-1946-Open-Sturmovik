[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = [IO.Path]::GetFullPath($RepositoryRoot)
$switchRoot = Join-Path $root '_Game Switchers'
$filesRoot = Join-Path $root 'Files'
$titleClass = '5D18E55E5DF1D418'
$work = Join-Path ([IO.Path]::GetTempPath()) ('open-sturmovik-branding-' + [guid]::NewGuid().ToString('N'))
$exports = @(
    '--add-exports', 'java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED',
    '--add-exports', 'java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED'
)

$moddedProfiles = @(
    [pscustomobject]@{ Folder = '4.08 Mod ON (NO 6DOF)'; Kind = 'No6Dof'; SourceHash = '622CFD3F3F5C3D7AA7106AE7DE177B8F58A678715385CA58B674651084FBCC0F'; FinalHash = '70B3F84EDD111921B93CDFD720D6394764DD7C40249D0CD3617B18A7A3F990D3' },
    [pscustomobject]@{ Folder = '4.08 Mods 6DOF ON'; Kind = '6Dof'; SourceHash = '68C78F7F981BDDF4B6FB3A6FF901B59115AE7B3D953B8F53121E6BE5B8A65584'; FinalHash = 'F43C999779B599102146A19E644DF7B56E20A5995E3D060C7D80C958BCDD845E' },
    [pscustomobject]@{ Folder = '4.09 Mods ON (NO 6DOF)'; Kind = 'No6Dof'; SourceHash = '622CFD3F3F5C3D7AA7106AE7DE177B8F58A678715385CA58B674651084FBCC0F'; FinalHash = '70B3F84EDD111921B93CDFD720D6394764DD7C40249D0CD3617B18A7A3F990D3' },
    [pscustomobject]@{ Folder = '4.09 Mods 6DOF ON'; Kind = '6Dof'; SourceHash = '68C78F7F981BDDF4B6FB3A6FF901B59115AE7B3D953B8F53121E6BE5B8A65584'; FinalHash = 'F43C999779B599102146A19E644DF7B56E20A5995E3D060C7D80C958BCDD845E' },
    [pscustomobject]@{ Folder = '4.09finalModsON(No-6DoF)'; Kind = 'No6Dof'; SourceHash = '622CFD3F3F5C3D7AA7106AE7DE177B8F58A678715385CA58B674651084FBCC0F'; FinalHash = '70B3F84EDD111921B93CDFD720D6394764DD7C40249D0CD3617B18A7A3F990D3' },
    [pscustomobject]@{ Folder = '4.09final_ModsON+6DoF'; Kind = '6Dof'; SourceHash = '68C78F7F981BDDF4B6FB3A6FF901B59115AE7B3D953B8F53121E6BE5B8A65584'; FinalHash = 'F43C999779B599102146A19E644DF7B56E20A5995E3D060C7D80C958BCDD845E' }
)
$originalProfiles = @(
    '4.08 Mods OFF (Original)',
    '4.09 Mods OFF (Original)',
    '4.09finalModsOFF(Original)'
)
$originalHash = '9ACE9A542AC7203D8A66961570B6854C11FB0BF721F0234DA9D6095D69D2525C'

try {
    New-Item -ItemType Directory -Path $work -Force | Out-Null
    $unique = @{}
    foreach ($profile in $moddedProfiles) {
        if (-not $unique.ContainsKey($profile.Kind)) {
            $source = Join-Path (Join-Path $switchRoot $profile.Folder) 'il2fb.exe'
            $sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
            $output = Join-Path $work ($profile.Kind + '-il2fb.exe')
            if ($sourceHash -eq $profile.SourceHash) {
                $result = & (Join-Path $root 'tools\Set-OpenSturmovikExeBranding.ps1') `
                    -InputPath $source -OutputPath $output -ExpectedSha256 $profile.SourceHash
            }
            elseif ($sourceHash -eq $profile.FinalHash) {
                Copy-Item -LiteralPath $source -Destination $output -Force
                $result = [pscustomobject]@{ InputAlreadyBranded = $true }
            }
            else {
                throw "Source EXE inattendue pour $($profile.Folder)."
            }
            if ((Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash -ne $profile.FinalHash) {
                throw "EXE marque non reproductible pour $($profile.Kind)."
            }
            $version = (Get-Item -LiteralPath $output).VersionInfo
            if ($version.FileDescription -ne 'Open Sturmovik' -or $version.ProductName -ne 'Open Sturmovik') {
                throw "Metadonnees Open Sturmovik absentes pour $($profile.Kind)."
            }
            $unique[$profile.Kind] = [pscustomobject]@{ Path = $output; Result = $result }
        }
    }

    foreach ($profile in $moddedProfiles) {
        $target = Join-Path (Join-Path $switchRoot $profile.Folder) 'il2fb.exe'
        Copy-Item -LiteralPath $unique[$profile.Kind].Path -Destination $target -Force
    }

    foreach ($folder in $originalProfiles) {
        $path = Join-Path (Join-Path $switchRoot $folder) 'il2fb.exe'
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $originalHash) {
            throw "L executable original a change : $folder"
        }
        $version = (Get-Item -LiteralPath $path).VersionInfo
        if ($version.FileDescription -eq 'Open Sturmovik' -or $version.ProductName -eq 'Open Sturmovik') {
            throw "L executable original porte par erreur la marque Open Sturmovik : $folder"
        }
    }

    $sourceTitle = Join-Path $filesRoot $titleClass
    $sourceTitleHash = (Get-FileHash -LiteralPath $sourceTitle -Algorithm SHA256).Hash
    $sourceTitleHashBefore = '45586634CD777F2DF6DB7463F8047806CBE11E71987883152AF32850BA6728D1'
    $constructorOnlyHash = '113E72DC1429DA8BBE33DF1FA7A659C584CA2124A01A3834B10309737280BC15'
    $sourceTitleHashFinal = '8CEF8D5EC9EAAAC27D2797462E33B9FC5EED4506C3B8B273B4553292CBA20A94'
    if ($sourceTitleHash -in @($sourceTitleHashBefore, $constructorOnlyHash)) {
        $patcherClasses = Join-Path $work 'patcher'
        New-Item -ItemType Directory -Path $patcherClasses -Force | Out-Null
        $javac = (Get-Command javac -ErrorAction Stop).Source
        $java = (Get-Command java -ErrorAction Stop).Source
        & $javac @exports -d $patcherClasses (Join-Path $root 'tools\java\OpenSturmovikWindowTitlePatcher.java')
        if ($LASTEXITCODE -ne 0) {
            throw 'Compilation du patcher de titre impossible.'
        }
        $patchedTitle = Join-Path $work 'Config.class'
        & $java @exports -cp $patcherClasses OpenSturmovikWindowTitlePatcher $sourceTitle $patchedTitle
        if ($LASTEXITCODE -ne 0) {
            throw 'Modification du titre de fenetre impossible.'
        }
        if ((Get-FileHash -LiteralPath $patchedTitle).Hash -ne $sourceTitleHashFinal) {
            throw 'Classe construite non conforme ; fichier actif conserve.'
        }
        Copy-Item -LiteralPath $patchedTitle -Destination $sourceTitle -Force
    }
    elseif ($sourceTitleHash -ne $sourceTitleHashFinal) {
        throw "Classe Config source inattendue : $sourceTitleHash"
    }
    if ((Get-FileHash -LiteralPath $sourceTitle -Algorithm SHA256).Hash -ne $sourceTitleHashFinal) {
        throw 'La classe de titre Open Sturmovik finale ne correspond pas a la reference.'
    }

    [pscustomobject]@{
        ModdedExecutables = $moddedProfiles.Count
        OriginalExecutablesVerified = $originalProfiles.Count
        No6DofSha256 = (Get-FileHash -LiteralPath $unique.No6Dof.Path -Algorithm SHA256).Hash
        SixDofSha256 = (Get-FileHash -LiteralPath $unique.'6Dof'.Path -Algorithm SHA256).Hash
        WindowTitleClass = $titleClass
        WindowTitleClassSha256 = (Get-FileHash -LiteralPath $sourceTitle -Algorithm SHA256).Hash
        Result = 'PASS'
    }
} finally {
    if (Test-Path -LiteralPath $work -PathType Container) {
        $resolvedWork = (Resolve-Path -LiteralPath $work).Path
        $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')
        if (-not $resolvedWork.StartsWith($tempRoot + '\', [StringComparison]::OrdinalIgnoreCase) -or
            (Split-Path -Leaf $resolvedWork) -notmatch '^open-sturmovik-branding-[a-f0-9]{32}$') {
            throw 'Dossier temporaire inattendu ; nettoyage refuse.'
        }
        Remove-Item -LiteralPath $resolvedWork -Recurse -Force
    }
}
