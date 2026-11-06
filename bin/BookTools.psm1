<#
    "ConvertToRoman", "Transliterate", OrdinalsWordRu" | ForEach-Object { . "$env:USERPROFILE\Мой диск\bin\$_.ps1" }

    $ordinals = @("0", "перв", "втор", "трет", "четверт", "пят", "шест", "седьм", "восьм", "девят", "десят",
                "одиннадцат", "двенадцат", "тринадцат", "четырнадцат", "пятнадцат", "шестнадцат", "семнадцат",
                "восемнадцат", "девятнадцат", "двадцат", "двадцать перв", "двадцать втор", "двадцать трет", `
                "двадцать четверт", "двадцать пят", "двадцать шест", "двадцать седьм", "двадцать восьм", `
                "двадцать девят", "тридцат", "тридцать перв", "тридцать втор", "тридцать трет", `
                "тридцать четверт", "тридцать пят", "тридцать шест", "тридцать седьм", "тридцать восьм", `
                "тридцать девят", "сороков", "сорок перв", "сорок втор", "сорок трет", "сорок четверт", `
                "сорок пят", "сорок шест", "сорок седьм", "сорок восьм", "сорок девят", "пятидесят")
#>    

# Два простых и строго упорядоченных массива в области видимости скрипта
if ($null -eq $script:RomanValues) {
    $script:RomanValues = [int[]](1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1)
    $script:RomanSymbols = [string[]]("M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I")
}

function ConvertToRoman {
    param (
        [ValidateRange(1, 3999)]
        [int]$Number
    )

    $sb = [System.Text.StringBuilder]::new(16)
    $current = $Number

    # Перебираем индексы массивов от 0 до 12
    for ($i = 0; $i -lt $script:RomanValues.Length; $i++) {
        $value = $script:RomanValues[$i]
        
        while ($current -ge $value) {
            [void]$sb.Append($script:RomanSymbols[$i])
            $current -= $value
        }
        
        if ($current -eq 0) { break }
    }

    return $sb.ToString()
}

if ($null -eq $script:TensMap) {
    # Чистый .NET-словарь работает быстрее стандартной хэш-таблицы PowerShell
    $script:TensMap = [System.Collections.Generic.Dictionary[int, string]]::new()
    $script:TensMap.Add(2, 'двадцать')
    $script:TensMap.Add(3, 'тридцать')
    $script:TensMap.Add(4, 'сорок')
    $script:TensMap.Add(5, 'пятьдесят')
    $script:TensMap.Add(6, 'шестьдесят')
    $script:TensMap.Add(7, 'семьдесят')
    $script:TensMap.Add(8, 'восемьдесят')
    $script:TensMap.Add(9, 'девяносто')
}

if ($null -eq $script:UnitsMap) {
    # Строго типизированный массив строк для мгновенного доступа по индексу
    $script:UnitsMap = [string[]]@(
        '', 'первый', 'второй', 'третий', 'четвёртый',
        'пятый', 'шестой', 'седьмой', 'восьмой', 'девятый'
    )
}

function Get-OrdinalRu {
    param(
        [int]$Number
    )

    switch ($Number) {
        # 1. Сначала проверяем граничные условия через блоки кода
        { $_ -lt 1 }  { throw "Поддерживаются только положительные числа." }
        { $_ -gt 99 } { return "${_}-й" }

        # 2. Исключения и круглые десятки (прямое и быстрое сопоставление)
        1  { 'первый' }
        2  { 'второй' }
        3  { 'третий' }
        4  { 'четвёртый' }
        5  { 'пятый' }
        6  { 'шестой' }
        7  { 'седьмой' }
        8  { 'восьмой' }
        9  { 'девятый' }
        10 { 'десятый' }
        11 { 'одиннадцатый' }
        12 { 'двенадцатый' }
        13 { 'тринадцатый' }
        14 { 'четырнадцатый' }
        15 { 'пятнадцатый' }
        16 { 'шестнадцатый' }
        17 { 'семнадцатый' }
        18 { 'восемнадцатый' }
        19 { 'девятнадцатый' }
        20 { 'двадцатый' }
        30 { 'тридцатый' }
        40 { 'сороковой' }
        50 { 'пятидесятый' }
        60 { 'шестидесятый' }
        70 { 'семидесятый' }
        80 { 'восьмидесятый' }
        90 { 'девяностый' }

        # 3. Логика для составных чисел (21-29, 31-39 и т.д.)
        default {
            $unit = 0
            $ten  = [math]::DivRem($_, 10, [ref]$unit)

            return "$($script:TensMap[$ten]) $($script:UnitsMap[$unit])"
        }
    }
}

# Создаем таблицу транслитерации ОДИН раз при запуске скрипта
$script:TranslitMap = @{
    [char]'х' = "h";  [char]'Х' = "H";  [char]'ц' = "c";   [char]'Ц' = "C"
    [char]'ч' = "ch"; [char]'Ч' = "Ch"; [char]'ш' = "sh";  [char]'Ш' = "Sh"
    [char]'щ' = "sch";[char]'Щ' = "Sch";[char]'ю' = "yu";  [char]'Ю' = "Yu"
    [char]'я' = "ya"; [char]'Я' = "Ya"; [char]'а' = "a";   [char]'А' = "A"
    [char]'б' = "b";  [char]'Б' = "B";  [char]'в' = "v";   [char]'В' = "V"
    [char]'г' = "g";  [char]'Г' = "G";  [char]'д' = "d";   [char]'Д' = "D"
    [char]'е' = "e";  [char]'Е' = "E";  [char]'ё' = "yo";  [char]'Ё' = "Yo"
    [char]'ж' = "zh"; [char]'Ж' = "Zh"; [char]'з' = "z";   [char]'З' = "Z"
    [char]'и' = "i";  [char]'И' = "I";  [char]'й' = "j";   [char]'Й' = "J"
    [char]'к' = "k";  [char]'К' = "K";  [char]'л' = "l";   [char]'Л' = "L"
    [char]'м' = "m";  [char]'М' = "M";  [char]'н' = "n";   [char]'Н' = "N"
    [char]'о' = "o";  [char]'О' = "O";  [char]'п' = "p";   [char]'П' = "P"
    [char]'р' = "r";  [char]'Р' = "R";  [char]'с' = "s";   [char]'С' = "S"
    [char]'т' = "t";  [char]'Т' = "T";  [char]'у' = "u";   [char]'У' = "U"
    [char]'ф' = "f";  [char]'Ф' = "F";  [char]'ъ' = "q";   [char]'Ъ' = ""
    [char]'ы' = "yi"; [char]'Ы' = "Yi"; [char]'ь' = "~";   [char]'Ь' = ""
    [char]'э' = "e";  [char]'Э' = "E";  [char]' ' = "_";   [char]':' = ""
}

function global:TranslitToLAT {
    param(
        [Parameter(Mandatory=$true)]
        [string]$InString
    )
    
    # Используем StringBuilder (выделяет буфер в памяти один раз и меняет его на месте)
    $sb = [System.Text.StringBuilder]::new($inString.Length * 2)

    # Быстрый посимвольный перебор строки
    # Перебираем символы по индексам строки напрямую (это 100% гарантирует тип [char] для .NET)
    for ($i = 0; $i -lt $inString.Length; $i++) {
        $c = $inString[$i] # Здесь $c гарантированно имеет тип [System.Char]

        if ($script:TranslitMap.ContainsKey($c)) {
            [void]$sb.Append($script:TranslitMap[$c])
        } else {
            [void]$sb.Append($c)
        }
    }

    # Возвращаем готовую строку
    return $sb.ToString()
}


function Get-AuthorName {
    param(
        # Явно указываем тип узла, чтобы PowerShell не тратил время на динамическое определение
        [System.Xml.XmlElement]$Node
    )
    
    # Пытаемся взять фамилию, если её нет — берем имя
    $lastName = $Node.'last-name'
    if (-not [string]::IsNullOrWhiteSpace($lastName)) { return $lastName.Trim() }
    
    $firstName = $Node.'first-name'
    if (-not [string]::IsNullOrWhiteSpace($firstName)) { return $firstName.Trim() }
    
    return "Unknown"
}

function Select-Author {
    param(
        # Строгая типизация для коллекции XML-узлов .NET
        [System.Collections.IList]$Nodes
    )
    
    Write-Host "`n[!] В файле найдено несколько авторов ($($Nodes.Count)). Требуется ваш выбор:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $Nodes.Count; $i++) {
        # Приведение к [string] и .Trim() вытащат чистый текст, либо оставят пустую строку ""
        Write-Host "[$($i + 1)]" $Nodes[$i].'last-name' $Nodes[$i].'first-name'
    }

    # Цикл безопасного ввода
    $choice = 0
    do {
        $rawInput = Read-Host "Введите номер нужного автора (от 1 до $($Nodes.Count))"
        $isValid = [int]::TryParse($rawInput, [ref]$choice) -and $choice -ge 1 -and $choice -le $Nodes.Count
        
        if (-not $isValid) {
            Write-Host "Ошибка: некорректный ввод. Попробуйте снова." -ForegroundColor Red
        }
    } until ($isValid)

    # Используем готовую функцию для получения чистого имени выбранного автора
    $Author = Get-AuthorName $Nodes[$choice - 1]
    Write-Host "`n[OK] Вы выбрали автора: $Author" -ForegroundColor Green
    
    return $Author
}

