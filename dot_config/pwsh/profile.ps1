Import-Module -Name Terminal-Icons
Import-Module PSReadLine
Import-Module PSFzf

Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }
$Env:FZF_DEFAULT_OPTS = '--height=80% --reverse --cycle --info=inline --pointer=">" --bind=ctrl-space:accept'
# $Env:FZF_CTRL_T_OPTS = '--preview "bat --color=always {}"'
$Env:FZF_ALT_C_OPTS = '--preview "tree {}"'

if (Get-Command scoop 2> $null) {
  $doUpdate = $true;
  if ($lastupdate = Get-Content "$env:LOCALAPPDATA\last-scoop-update-timestamp" 2> $null) {
    if ( (Get-Date -UnixTimeSeconds ([int64]$lastupdate + 30 * 24 * 3600)) -gt (Get-Date) ) {
      $doUpdate = $false
    }
  }
  if ($doUpdate) {
    scoop update
    scoop update -a
    scoop cleanup -a
    Get-Date -UFormat "%s" > "$env:LOCALAPPDATA\last-scoop-update-timestamp"
  }
}

$Env:MY_CURRENT_THEME = "dark"
if ( (Get-WindowsAppsTheme) -eq "light") { 
    $Env:MY_CURRENT_THEME = "light"
}

$D_USER = "D:\Users\$env:USERNAME\"

Remove-Item Alias:ls
Remove-Item Alias:clear
function clear {Write-Output "$([char]27)[H$([char]27)[2J" }
function c { clear }
function ls { Get-ChildItem | Format-Wide }
function ll { Get-ChildItem }
function la { Get-ChildItem -Force }
Set-Alias -Name vim -Value nvim
Set-Alias -Name open -Value explorer
function vimdiff { nvim -d $args }
Set-Alias -Name du -Value dust
Set-Alias -Name cz -Value chezmoi
function czcd { cd (chezmoi source-path) }

if (Get-Command tailscale 2> $null) {
    tailscale completion powershell | Out-String | Invoke-Expression
}

if (Get-Command chezmoi 2> $null) {
    chezmoi completion powershell | Out-String | Invoke-Expression
}

if (Get-Command oh-my-posh 2> $null) {
    $omp_theme_dark  = "$env:posh_themes_path/tokyo.omp.json"
    $omp_theme_light = "$env:posh_themes_path/quick-term.omp.json"
    $omp_theme = $omp_theme_dark;
    if ( $Env:MY_CURRENT_THEME -eq "light" ) {
        $omp_theme = $omp_theme_light
    }
    oh-my-posh init pwsh --config $omp_theme | invoke-expression
}
