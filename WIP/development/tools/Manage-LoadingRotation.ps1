#requires -Version 5.1
[CmdletBinding()]
param([string]$GameRoot, [string]$PreviewPath)
$ErrorActionPreference='Stop'
if ([string]::IsNullOrWhiteSpace($GameRoot)) { $GameRoot=Split-Path -Parent $PSScriptRoot }
Import-Module (Join-Path $PSScriptRoot 'OpenSturmovik.LoadingRotation.psm1') -Force
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()
$catalog=@(Get-OSLoadingCatalog)
$state=Set-OSLoadingRotation -GameRoot $GameRoot -Action Status
$form=New-Object Windows.Forms.Form
$form.Text="Open Sturmovik - Fonds de chargement"
$form.ClientSize=New-Object Drawing.Size(960,620)
$form.StartPosition='CenterScreen'
$form.FormBorderStyle='FixedDialog'
$form.MaximizeBox=$false
$form.Font=New-Object Drawing.Font('Segoe UI',10)
$form.BackColor=[Drawing.Color]::FromArgb(244,244,239)
function Label([string]$Text,[int]$X,[int]$Y,[int]$W,[int]$H) {
    $label=New-Object Windows.Forms.Label
    $label.Text=$Text;$label.Location=New-Object Drawing.Point($X,$Y);$label.Size=New-Object Drawing.Size($W,$H)
    $form.Controls.Add($label)
    return $label
}
$title=Label 'Un fond différent à chaque démarrage' 24 18 900 40
$title.Font=New-Object Drawing.Font('Segoe UI',18,[Drawing.FontStyle]::Bold)
$intro=Label 'Fonctionne aussi en ouvrant directement il2fb.exe. Le mode IL-2 stock conserve son fond habituel.' 24 62 908 34
$hint=Label 'Fonds disponibles dans le jeu — cochez les images à utiliser (2 à 4).' 24 108 910 26
$list=New-Object Windows.Forms.CheckedListBox
$list.Location=New-Object Drawing.Point(24,140);$list.Size=New-Object Drawing.Size(442,172)
$list.CheckOnClick=$true;$list.BorderStyle='FixedSingle'
foreach ($image in $catalog) {
    $index=$list.Items.Add($image.label)
    if ($image.id -in $state.configuration.images) { $list.SetItemChecked($index,$true) }
}
$form.Controls.Add($list)
$preview=New-Object Windows.Forms.PictureBox
$preview.Location=New-Object Drawing.Point(494,140);$preview.Size=New-Object Drawing.Size(440,275)
$preview.SizeMode='Zoom';$preview.BackColor=[Drawing.Color]::FromArgb(35,40,42)
$form.Controls.Add($preview)
$officialLabel=Label 'Fond officiel : trois passages par cycle' 24 326 435 25
$official=New-Object Windows.Forms.ComboBox
$official.Location=New-Object Drawing.Point(24,355);$official.Size=New-Object Drawing.Size(442,30)
$official.DropDownStyle='DropDownList'
$form.Controls.Add($official)
$script:officialIds=@('')
function Sync-OfficialChoices {
    $keep=if ($official.SelectedIndex -ge 0 -and $official.SelectedIndex -lt $script:officialIds.Count) { $script:officialIds[$official.SelectedIndex] } else { $state.configuration.official }
    $official.Items.Clear()
    [void]$official.Items.Add('Aucun — mêmes fréquences')
    $script:officialIds=@('')
    foreach ($i in $list.CheckedIndices) {
        [void]$official.Items.Add($catalog[[int]$i].label)
        $script:officialIds+= $catalog[[int]$i].id
    }
    $official.SelectedIndex=0
    for ($i=1;$i -lt $script:officialIds.Count;$i++) { if ($script:officialIds[$i] -eq $keep) { $official.SelectedIndex=$i } }
}
$modeLabel=Label 'Ordre des passages' 24 398 420 25
$mode=New-Object Windows.Forms.ComboBox
$mode.Location=New-Object Drawing.Point(24,428);$mode.Size=New-Object Drawing.Size(442,30);$mode.DropDownStyle='DropDownList'
[void]$mode.Items.Add('Mélangé à chaque cycle, sans répétition immédiate')
[void]$mode.Items.Add('Ordre régulier, sans répétition immédiate')
$mode.SelectedIndex=if ($state.configuration.mode -eq 'ordered') { 1 } else { 0 }
$form.Controls.Add($mode)
$explanation=Label 'Le fond officiel reçoit trois places ; chaque autre fond en reçoit une. Il faut quatre images pour tripler sa fréquence sans répétition immédiate.' 494 432 440 66
$status=Label '' 24 487 442 50
$status.ForeColor=[Drawing.Color]::FromArgb(40,90,64)
function Update-State {
    $script:state=Set-OSLoadingRotation -GameRoot $GameRoot -Action Status
    $status.Text=if (-not $script:state.installed) { 'Mécanisme non installé.' } elseif ($script:state.configuration.enabled) { 'Rotation activée pour le prochain démarrage.' } else { 'Rotation désactivée. Votre fond habituel reste utilisé.' }
}
function Button([string]$Text,[int]$X,[int]$W) {
    $b=New-Object Windows.Forms.Button
    $b.Text=$Text;$b.Location=New-Object Drawing.Point($X,551);$b.Size=New-Object Drawing.Size($W,42)
    $form.Controls.Add($b);return $b
}
$enable=Button 'Enregistrer et activer' 24 225
$disable=Button 'Désactiver' 263 180
$remove=Button 'Retirer la modification' 457 235
$close=Button 'Fermer' 760 174
$list.add_SelectedIndexChanged({
    if ($list.SelectedIndex -lt 0) { return }
    if ($null -ne $preview.Image) { $preview.Image.Dispose();$preview.Image=$null }
    $fileImage=[Drawing.Image]::FromFile($catalog[$list.SelectedIndex].source)
    try { $preview.Image=New-Object Drawing.Bitmap($fileImage) } finally { $fileImage.Dispose() }
})
$list.add_ItemCheck({ if ($form.IsHandleCreated) { [void]$form.BeginInvoke([Action]{Sync-OfficialChoices}) } })
$enable.add_Click({
    try {
        $ids=@($list.CheckedIndices | ForEach-Object { $catalog[[int]$_].id })
        $officialId=$script:officialIds[$official.SelectedIndex]
        if ($ids.Count -lt 2 -or $ids.Count -gt 4) { throw 'Cochez entre deux et quatre images.' }
        if ($officialId -and $ids.Count -lt 4) { throw 'Choisissez quatre images pour tripler le fond officiel.' }
        if (-not (Set-OSLoadingRotation -GameRoot $GameRoot -Action Status).installed) {
            $null=Set-OSLoadingRotation -GameRoot $GameRoot -Action Install
        }
        $choiceMode=if ($mode.SelectedIndex -eq 1) { 'ordered' } else { 'shuffle' }
        $null=Set-OSLoadingRotation -GameRoot $GameRoot -Action Enable -ImageIds $ids -OfficialId $officialId -Mode $choiceMode
        Update-State
    } catch { [void][Windows.Forms.MessageBox]::Show($form,$_.Exception.Message,'Fonds de chargement','OK','Warning') }
})
$disable.add_Click({
    try { $null=Set-OSLoadingRotation -GameRoot $GameRoot -Action Disable;Update-State }
    catch { [void][Windows.Forms.MessageBox]::Show($form,$_.Exception.Message,'Fonds de chargement','OK','Warning') }
})
$remove.add_Click({
    try {
        $result=Set-OSLoadingRotation -GameRoot $GameRoot -Action Remove
        Update-State
        $message="Le code et les ressources ajoutés ont été retirés. Les sauvegardes sont conservées."
        if (@($result.preserved).Count) { $message += [Environment]::NewLine + 'Vos fichiers modifiés manuellement ont été préservés.' }
        [void][Windows.Forms.MessageBox]::Show($form,$message,'Retour arrière','OK','Information')
    } catch { [void][Windows.Forms.MessageBox]::Show($form,$_.Exception.Message,'Retour arrière','OK','Warning') }
})
$close.add_Click({$form.Close()})
Sync-OfficialChoices
Update-State
if ($catalog.Count) { $list.SelectedIndex=0 }
try {
    if ($PreviewPath) {
        $form.ShowInTaskbar=$false; $form.Opacity=0; $form.Show(); [Windows.Forms.Application]::DoEvents()
        foreach ($control in $form.Controls) { $control.CreateControl() }
        $bitmap=New-Object Drawing.Bitmap($form.Width,$form.Height)
        try {
            $form.DrawToBitmap($bitmap,(New-Object Drawing.Rectangle(0,0,$form.Width,$form.Height)))
            $bitmap.Save([IO.Path]::GetFullPath($PreviewPath),[Drawing.Imaging.ImageFormat]::Png)
        } finally { $bitmap.Dispose() }
    } else { [void]$form.ShowDialog() }
} finally {
    if ($null -ne $preview.Image) { $preview.Image.Dispose() }
    $form.Dispose()
}
