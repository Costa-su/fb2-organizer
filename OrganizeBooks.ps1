$BinPath = Join-Path $PSScriptRoot "bin"
. $BinPath\MoveToRecycleBin.ps1
. $BinPath\FictBookNaming.ps1

Add-Type -AssemblyName System.IO.Compression.FileSystem

$Books = "$env:USERPROFILE\Downloads"
$BooksLib = "$env:USERPROFILE\Books\"

$archivesToRemove = [System.Collections.Generic.List[string]]::new()

foreach ($arch in Get-ChildItem -Path $Books -Filter "*.zip") {
    Write-Verbose "Распаковка: $($arch.Name)"
    
    try {
        # Сверхбыстрая распаковка
        [System.IO.Compression.ZipFile]::ExtractToDirectory($arch.FullName, $arch.DirectoryName)
        
        # Добавляем в список ТОЛЬКО если распаковка прошла успешно
        $archivesToRemove.Add($arch.FullName)
    }
    catch {
        Write-Error "Не удалось распаковать архив '$($arch.Name)': $_"
        # Архив остается на месте, в список удаления не попадает
    }
}

# Тихое удаление всей пачки файлов в Корзину
if ($archivesToRemove.Count -gt 0) {
    Protect-Remove -Path $archivesToRemove.ToArray()
}

# 1. Получаем список файлов в память (выбираем только нужные для скорости)
$fb2Files = Get-ChildItem -Path $Books -Filter "*.fb2"

# Получаем текущую дату ОДИН раз до цикла, чтобы не вызывать Get-Date на каждом файле
$currentDate = Get-Date

# 2. Обрабатываем каждый файл
foreach ($file in $fb2Files) {
    $newName = Get-FictBookName $file.FullName
    
    if (-not [string]::IsNullOrWhiteSpace($newName) -and $newName -ne $file.Name) {
        
        # Используем быстрый .NET метод для переименования
        $destinationPath = Join-Path $file.DirectoryName $newName
        [System.IO.File]::Move($file.FullName, $destinationPath)
        
        Write-Host "$($file.Name) --> $newName"
        
        # Обновляем дату файла через .NET
        [System.IO.File]::SetLastWriteTime($destinationPath, $currentDate)
    }
}

$oldCulture = [System.Threading.Thread]::CurrentThread.CurrentUICulture
[System.Threading.Thread]::CurrentThread.CurrentUICulture = 'en-US'
Move-Item -Path "$Books\*.fb2" -Destination $BooksLib -Confirm
[System.Threading.Thread]::CurrentThread.CurrentUICulture = $oldCulture