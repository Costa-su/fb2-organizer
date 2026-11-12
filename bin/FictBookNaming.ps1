# ==============================================================================
# ИНИЦИАЛИЗАЦИЯ И ДИСКОВЫЕ ОПЕРАЦИИ (Выполняются строго 1 раз при запуске файла)
# ==============================================================================

# 1. Загружаем необходимые модули один раз для всей сессии
Import-Module (Join-Path $PSScriptRoot "BookTools.psm1") -ErrorAction Stop

# 2. Инициализируем глобальные кэши и таблицы
if ($null -eq $script:SeriesAuthorCache) {
    $script:SeriesAuthorCache = @{}
}

# (Сюда же переезжает таблица $script:TranslitMap, если она используется здесь)


# ==============================================================================
# ОПИСАНИЕ ФУНКЦИЙ (Чистая логика в памяти, без дисковых накладных расходов)
# ==============================================================================

function Get-FictBookName {
    [CmdletBinding()]
    param(
        [string]$FileFullPath
    )

    # Быстрое и строгое создание XmlDocument
    $xml = [System.Xml.XmlDocument]::new()
    try {
        $xml.Load($FileFullPath)
    } catch {
        return "Unknown_BadXMLFile.fb2"
    }

    $TitleNodes = $xml.FictionBook.description.'title-info'
    if ($null -eq $TitleNodes) { return "Unknown_NoTitle" }

    # Извлекаем серию (если её нет в XML, возвращается $null)
    $Seria = $TitleNodes.sequence.name
    if ([string]::IsNullOrWhiteSpace($Seria)) { 
        $Seria = $null 
    } else {
        $Seria = $Seria.Trim()
    }

    # Логика определения автора
    $Authors = @($TitleNodes.author)
    switch ($Authors.Count) {
        0 { $Author = "Unknown" }
        1 { $Author = Get-AuthorName $Authors[0] }
        default { 
            # Хэш-таблицу задействуем только при наличии серии
            $SeriesKey = if ($Seria) { $Seria.ToLower() } else { $null }
            
            # Проверяем, есть ли уже сохраненный автор для этой серии
            if ($SeriesKey -and $script:SeriesAuthorCache.ContainsKey($SeriesKey)) {
                $Author = $script:SeriesAuthorCache[$SeriesKey]
                Write-Verbose "Для серии '$Seria' автоматически применен автор из кэша: $Author"
            } else {
                # Интерактивный выбор, если серии нет или она еще не встречалась
                $Author = Select-Author -Nodes $Authors
                
                # Запоминаем выбор
                if ($SeriesKey -and -not [string]::IsNullOrWhiteSpace($Author)) {
                    $script:SeriesAuthorCache[$SeriesKey] = $Author
                }
            }
        }
    }

    # Логика обработки номера серии
    $Number = $TitleNodes.sequence.number
    if ([string]::IsNullOrWhiteSpace($Number)) {
        $Number   = $null
    } else {
        $Number = $Number.TrimStart('0')
        $RomanNum = ConvertToRoman $Number
        $TextNum = Get-OrdinalRu $Number
        # Отрезаем окончание и формируем готовый паттерн для регулярного выражения
        $TextPattern = if ([int]$Number -le 99) {
            "$($TextNum.Remove($TextNum.Length - 2))[а-яё]{2}"
        } else {
            [regex]::Escape($TextNum)
        }
        $NumPattern = "\b((том|книга|часть)\s*)?(0*$Number|$RomanNum|$TextPattern)\b"
   }

    # ==============================================================================
    # 1. Точечное удаление серии и номера из самого Title (защита от дублирования)
    # ==============================================================================
    $Title = $TitleNodes.'book-title'

    if ($Seria) {
        $Title = [regex]::Replace($Title, "\b$([regex]::Escape($Seria))\b", " ",
                 [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    }

    if ($Number) {
        $Title = [regex]::Replace($Title, $NumPattern, " ",
                 [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    }

    # ==============================================================================
    # 2. ФИНАЛЬНАЯ СБОРКА И ПОЛНАЯ ОЧИСТКА ВСЕГО ИМЕНИ (В один проход)
    # ==============================================================================
    
    # 1. Склеиваем и удаляем всю пунктуацию, заменяя на пробелы
    $CleanName = [regex]::Replace("${Author}_${Seria}_${Number}_${Title}", "[^\w\s_]+", " ")
    
    # 2. Схлопываем пробелы/подчеркивания и сразу обрезаем края цепочкой методов .NET
    $FinalName = [regex]::Replace($CleanName, "[\s_]+", "_").Trim('_')
    
    # Отправляем идеально чистую строку в транслит и добавляем расширение
    return "$(TranslitToLAT $FinalName).fb2"
}