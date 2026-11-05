function Protect-Remove {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('FullName')]
        [string[]]$Path
    )

    begin {
        # Загружаем сборку один раз при старте
        Add-Type -AssemblyName Microsoft.VisualBasic
    }

process {
    foreach ($literalPath in $Path) {
        if ([string]::IsNullOrWhiteSpace($literalPath)) { continue }

        # Сразу отсекаем несуществующие элементы (Guard Clause)
        if (-not [System.IO.File]::Exists($literalPath) -and -not [System.IO.Directory]::Exists($literalPath)) {
            Write-Warning "Файл или папка не найдены: $literalPath"
            continue
        }

        try {
            # Удаление в Корзину без лишних диалоговых окон
            if ([System.IO.File]::Exists($literalPath)) {
                [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($literalPath, 'OnlyErrorDialogs', 'SendToRecycleBin')
            } else {
                # Для папок добавляется параметр удаления подпапок (RecycleOption)
                [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($literalPath, 'OnlyErrorDialogs', 'SendToRecycleBin')
            }
        } catch {
            Write-Warning "Ошибка удаления '$literalPath': $_"
        }
    }
}
}
