Import-Module PSReadLine

Import-Module PSFzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
$Env:FZF_DEFAULT_OPTS = '--reverse --cycle --info=inline --pointer=">" --bind=ctrl-space:accept'
# Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }
# $Env:FZF_CTRL_T_OPTS = '--preview "bat --color=always {}"'
$Env:FZF_ALT_C_OPTS = '--preview "eza --tree --icons=auto -L 2 {}"'

# use PSCompletions for Tab
Import-Module PSCompletions

$DUSER = "D:\Users\$env:USERNAME\"
$Env:EDITOR = "nvim"
$_theme = if ((Get-WindowsAppsTheme) -eq "light") { "light" } else { "dark" }

Remove-Item Alias:clear
function clear {Write-Output "$([char]27)[H$([char]27)[2J" }
function c { clear }

function l  { eza --icons=auto     $args }
function ll { eza --icons=auto -l  $args }
function la { eza --icons=auto -la $args }
function tree { eza --tree --icons=auto $args }

Set-Alias -Name open -Value explorer

Set-Alias -Name vim -Value nvim
function vimdiff { nvim -d $args }

Set-Alias -Name cz -Value chezmoi
function czcd { cd (chezmoi source-path) }

if (Get-Command tailscale 2> $null) {
    tailscale completion powershell | Out-String | Invoke-Expression
}

if (Get-Command chezmoi 2> $null) {
    chezmoi completion powershell | Out-String | Invoke-Expression
}

if (Get-Command oh-my-posh 2> $null) {
    $omp_theme_dark  = "$env:posh_themes_path/di4am0nd.omp.json"
    $omp_theme_light = "$env:posh_themes_path/negligible.omp.json"
    $omp_theme = if ($_theme -eq "light") { $omp_theme_light } else { $omp_theme_dark }
    oh-my-posh init pwsh --config $omp_theme | invoke-expression
}

function jabba
{
    $fd3=$([System.IO.Path]::GetTempFileName())
    $command="& '$Env:JABBA_HOME\bin\jabba.exe' $args --fd3 `"$fd3`""
    & { $env:JABBA_SHELL_INTEGRATION="ON"; Invoke-Expression $command }
    $fd3content=$(Get-Content $fd3)
    if ($fd3content) {
        $expression=$fd3content.replace("export ","`$env:").replace("unset ","Remove-Item env:") -join "`n"
        if (-not $expression -eq "") { Invoke-Expression $expression }
    }
    Remove-Item -Force $fd3
}

# auto scoop update
if (Get-Command scoop 2> $null) {
  $doUpdate = $true;
  if ($lastupdate = Get-Content "$env:LOCALAPPDATA\last-scoop-update-timestamp" 2> $null) {
    if ( (Get-Date -UnixTimeSeconds ([int64]$lastupdate + 30 * 24 * 3600)) -gt (Get-Date) ) {
      $doUpdate = $false
    }
  }

  if ($doUpdate) {
      $continue = Read-Host -Prompt "Do you want to update Scoop? Y/N"
        if (($continue -eq 'Y') -or ($continue -eq 'y')) {
            scoop update
            scoop update -a
            scoop cleanup -a
            Get-Date -UFormat "%s" > "$env:LOCALAPPDATA\last-scoop-update-timestamp"
        } else {
            Write-Output "Skipping update"
        }
  }
}
