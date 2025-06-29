# Função utilitária: mostra o caminho de um comando (como 'which' do Unix)
function Get-CommandPath {
    <#
    .SYNOPSIS
    Localiza o caminho completo de um comando.

    .PARAMETER Command
    Nome do comando a ser localizado.

    .EXAMPLE
    Get-CommandPath ping
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$Command
    )

    $result = Get-Command -Name $Command -ErrorAction SilentlyContinue
    if ($result) {
        $result.Path
    } else {
        Write-Host "Comando '$Command' não encontrado." -ForegroundColor Yellow
    }
}

function Clear-HistoryAmpersand {
    $historyFile = (Get-PSReadLineOption).HistorySavePath
    if (-not (Test-Path $historyFile)) { return }
    $lines = Get-Content $historyFile
    $filteredLines = $lines | Where-Object { -not ($_ -match '^\s*&') }
    Set-Content -Path $historyFile -Value $filteredLines -Encoding UTF8
    Write-Host "🧹 Linhas iniciadas com '&' removidas do arquivo de histórico." -ForegroundColor Green
}

Set-Alias nh Clear-HistoryAmpersand

# Opcional: Limpar automaticamente ao sair da sessão
Register-EngineEvent PowerShell.Exiting -Action { Clear-HistoryAmpersand } | Out-Null

function Compress-PSHistory {
    <#
    .SYNOPSIS
    Remove comandos duplicados (iguais) do arquivo de histórico do PSReadLine.

    .DESCRIPTION
    Lê o histórico salvo no arquivo, remove comandos repetidos mantendo apenas a primeira
    ocorrência de cada um, e grava o resultado limpo no mesmo arquivo.

    .EXAMPLE
    Compress
    #>

    $historyFile = (Get-PSReadLineOption).HistorySavePath

    if (-not (Test-Path $historyFile)) {
        Write-Warning "Arquivo de histórico não encontrado."
        return
    }

    $lines = Get-Content $historyFile
    $seen = @{}
    $unique = @()

    foreach ($line in $lines) {
        $trimmed = $line.TrimEnd()

        if (-not $seen.ContainsKey($trimmed)) {
            $seen[$trimmed] = $true
            $unique += $line
        }
    }

    Set-Content -Path $historyFile -Value $unique -Encoding UTF8

    $removed = $lines.Count - $unique.Count
    Write-Host "✅ Histórico comprimido: $removed comandos duplicados removidos." -ForegroundColor Green
}

# Alias para comando curto
Set-Alias Compress Compress-PSHistory
