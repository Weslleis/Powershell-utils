# Utilitários PowerShell para Histórico e Localização de Comandos

Este documento reúne um conjunto de funções utilitárias em PowerShell para:

- Localizar o caminho de comandos no sistema (como `which` no Unix).
- Limpar o histórico do PowerShell (`PSReadLine`) de entradas não desejadas.
- Remover duplicatas do histórico de comandos.

---

## 🔎 `Get-CommandPath` — Localiza o Caminho de um Comando

Similar ao `which` do Unix, essa função retorna o caminho completo de um comando no sistema.

```powershell
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
```

### ▶️ Exemplo de uso

```powershell
Get-CommandPath notepad
```

---

## 🧹 `nh` — Limpa Linhas com `&` do Histórico

Alias para `Clear-HistoryAmpersand`, essa função remove do histórico comandos iniciados com o operador `&`.

### ✅ Comportamento

- Remove comandos como:
  ```powershell
  & python script.py
  & "C:/meuscript.ps1"
  ```
- Mantém comandos que contenham `&` no meio, mas **não no início**.

### ▶️ Uso

```powershell
nh
```

### 💾 Implementação

```powershell
function Clear-HistoryAmpersand {
    $historyFile = (Get-PSReadLineOption).HistorySavePath
    if (-not (Test-Path $historyFile)) { return }
    $lines = Get-Content $historyFile
    $filteredLines = $lines | Where-Object { -not ($_ -match '^\s*&') }
    Set-Content -Path $historyFile -Value $filteredLines -Encoding UTF8
    Write-Host "🧹 Linhas iniciadas com '&' removidas do arquivo de histórico." -ForegroundColor Green
}

Set-Alias nh Clear-HistoryAmpersand
```

---

## 🔧 `Compress` — Remove Duplicatas do Histórico

Alias para `Compress-PSHistory`, essa função limpa comandos duplicados do histórico do PSReadLine.

### ✅ Comportamento

- Remove comandos idênticos, mantendo apenas a **primeira ocorrência**.
- Comandos similares com parâmetros diferentes são mantidos.

#### Exemplo:

**Antes:**

```
winget update
winget update
winget update vlc
winget update git
get-process
get-process
```

**Depois:**

```
winget update
winget update vlc
winget update git
get-process
```

### ▶️ Uso

```powershell
Compress
```

### 💾 Implementação

```powershell
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

Set-Alias Compress Compress-PSHistory
```

---

## ⚙️ Instalação no Perfil

Para tornar os comandos permanentes:

1. Abra seu perfil:

```powershell
notepad $PROFILE
```

2. Cole todas as funções e aliases neste arquivo e salve.

---

## 💡 Automação ao Encerrar a Sessão

Você pode automatizar a limpeza do histórico adicionando:

```powershell
Register-EngineEvent PowerShell.Exiting -Action {
    Clear-HistoryAmpersand
    Compress-PSHistory
} | Out-Null
```

---

## 📁 Backup do Histórico (Opcional)

Antes de modificar o histórico:

```powershell
Copy-Item (Get-PSReadLineOption).HistorySavePath "$env:USERPROFILE\ConsoleHost_history_backup.txt"
```

---

✅ Com isso, seu ambiente PowerShell ficará mais limpo, eficiente e com um histórico relevante e reutilizável.
