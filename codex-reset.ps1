#Requires -Version 5.1
<#
.SYNOPSIS
  Codex environment reset tool (safe uninstall)

.DESCRIPTION
  Remove configuration installed by awesome-claude-code-config
  without touching unrelated files.

.PARAMETER DryRun
  Show what would be removed without deleting.

.PARAMETER Force
  Skip confirmation prompt.
#>

param(
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference="Stop"

# =========================================================
# Paths
# =========================================================
$CODEX_DIR = Join-Path $HOME ".codex"
$AGENTS_DIR = Join-Path $HOME ".agents"
$SUPERPOWERS_LINK = Join-Path $HOME ".agents/skills/superpowers"
$SUPERPOWERS_DIR = Join-Path $HOME ".codex/superpowers"

# =========================================================
# Helpers
# =========================================================

function Info($m){Write-Host "[INFO] $m" -ForegroundColor Cyan}
function Warn($m){Write-Host "[WARN] $m" -ForegroundColor Yellow}
function Ok($m){Write-Host "[OK]   $m" -ForegroundColor Green}

function Confirm($msg){
    if($Force){return $true}
    $r=Read-Host "$msg [y/N]"
    return $r -match "^[Yy]$"
}

function SafeRemove($path){

    if(!(Test-Path $path)){return}

    if($DryRun){
        Warn "Would remove $path"
        return
    }

    Remove-Item -Recurse -Force $path -ErrorAction SilentlyContinue
    Ok "Removed $path"
}

# =========================================================
# Show plan
# =========================================================

Write-Host ""
Write-Host "======================================="
Write-Host " Codex Environment Reset"
Write-Host "======================================="
Write-Host ""

Info "The following items may be removed:"

Write-Host "  $CODEX_DIR"
Write-Host "  $SUPERPOWERS_DIR"
Write-Host "  $SUPERPOWERS_LINK"

Write-Host ""
Info "Registered MCP servers will also be removed (if codex CLI exists)."
Write-Host ""

if($DryRun){
    Warn "DRY RUN mode enabled."
}

if(!(Confirm "Proceed with reset?")){
    Info "Cancelled."
    exit
}

# =========================================================
# Remove MCP servers
# =========================================================

if(Get-Command codex -ErrorAction SilentlyContinue){

    Info "Removing MCP registrations..."

    if($DryRun){
        Warn "Would run: codex mcp remove context7"
        Warn "Would run: codex mcp remove github"
        Warn "Would run: codex mcp remove playwright"
        Warn "Would run: codex mcp remove lark-mcp"
        Warn "Would run: codex mcp remove openaiDeveloperDocs"
    }
    else{
        codex mcp remove context7 2>$null
        codex mcp remove github 2>$null
        codex mcp remove playwright 2>$null
        codex mcp remove lark-mcp 2>$null
        codex mcp remove openaiDeveloperDocs 2>$null
        Ok "MCP entries removed"
    }

}else{
    Warn "codex CLI not found, skipping MCP removal"
}

# =========================================================
# Remove superpowers junction
# =========================================================

if(Test-Path $SUPERPOWERS_LINK){

    $item = Get-Item $SUPERPOWERS_LINK -Force
    $isReparsePoint = ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0

    if($isReparsePoint){

        if($DryRun){
            Warn "Would remove junction $SUPERPOWERS_LINK"
        }else{
            cmd /c rmdir "$SUPERPOWERS_LINK" | Out-Null
            Ok "Removed junction $SUPERPOWERS_LINK"
        }

    }else{

        SafeRemove $SUPERPOWERS_LINK

    }
}

# =========================================================
# Remove directories
# =========================================================

SafeRemove $SUPERPOWERS_DIR
SafeRemove $CODEX_DIR

Write-Host ""
Ok "Codex environment reset complete."
Write-Host "You can now start Codex with a clean environment."
Write-Host ""