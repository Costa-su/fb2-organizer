# FB2 Book Organizer & Renamer (PowerShell)

🤖 *Читать это описание на [Русском языке](README.ru.md).*

A high-performance PowerShell automation toolkit designed for extracting, renaming, transliterating, and cataloging electronic books in the **FB2** format.

This project is built with a strong focus on execution speed. To bypass standard PowerShell overhead, file and string manipulations are performed using native **.NET framework** methods (e.g., `StringBuilder`, `XmlDocument`, `FileIO`).

## 🚀 Key Features

*   **Ultra-Fast Extraction:** Scans your downloads folder for all `.zip` archives, instantly extracts them via `.NET ZipFile`, and safely disposes of the processed archives. You should avoid store other archives as book's ones or can change downloads folder or use different filter mask (e.g. `*.zip` to `*fb2.zip`)
*   **Smart Metadata Renaming:** Parses the internal XML structure of FB2 files to automatically extract author names, book titles, series name, and the book's sequence number.
*   **Interactive Conflict Resolution:** If a book contains multiple authors, the script presents an interactive console menu for manual selection. The choice is automatically cached for the entire series to avoid repetitive prompts.
*   **Data Deduplication & Cleaning:** Prevents redundant data (e.g., if the series title is duplicated inside the book title), strips punctuation, and builds clean filenames using standard underscore (`_`) separators.
*   **Number Conversion:** Checks the title for a repeated series number, seaching by various formats: standard numerals, Roman numerals, and Russian ordinal number words (for example, if the series number is 21, "Title. Volume Twenty-First" will be reduced to just "Title," while "Title. Volume Second" will remain unchanged).
*   **Transliteration Layer:** Converts Cyrillic filenames into Latin characters using a strict, high-speed character-mapping table powered by a `.NET StringBuilder`. Table can be changed easily by your own taste in `BookTools.psm1`

## 🧱 Modular Architecture (Independent Usage)

A key design feature of this project is its **strict modularity**. The core operational scripts are intentionally decoupled and designed as **completely independent utilities**. 

This means you do not have to run the entire book-processing pipeline. You can use these components standalone in your own workflows:
*   **Safe Recycling Tool (`Protect-Remove`):** Can be called independently from any PowerShell console or embedded into other scripts to safely delete files and folders to the Windows Recycle Bin without prompt dialogs. It fully supports pipeline input (`ValueFromPipeline`).
*   **Book Parsing & Renamer (`Get-FictBookName`):** Can be used as a standalone function to test, preview, or bulk-rename FB2 metadata completely separately from the extraction and file-moving routines. (Do not forget to import proper module, e.g) 
   ```powershell
   . "C:\Path\To\fb2-book-organizer\bin\FictBookNaming.ps1"
   ```

## 📁 Repository Structure

The project is structured to run out of the box using relative paths via `$PSScriptRoot`:

```text
fb2-book-organizer/
├── OrganizeBooks.ps1          # Main execution entrypoint
├── LICENSE                    # MIT License file
├── README.md                  # Documentation (English)
├── README.ru.md               # Documentation (Russian)
└── bin/                       # Internal modules directory
    ├── MoveToRecycleBin.ps1   # Safe recycling utility (Protect-Remove)
    ├── FictBookNaming.ps1     # Core string, math, and transliteration helpers
    └── BookTools.psm1         # Binary / structural module loader
```

## ⚙️ Configuration & Environment

Open `OrganizeBooks.ps1` to adjust your target environment folders if necessary:
*   `$Books` — Target folder for incoming downloads (Defaults to `~\\Downloads`).
*   `$BooksLib` — Final curated book library destination (Defaults to `~\\Books\\`).

*The internal tools directory (`$BinPath`) is determined automatically relative to the script location.*

## 🛠 Usage & Requirements

1. Clone or download this repository onto your machine.
2. Open a PowerShell console and execute the main controller script:
   ```powershell
   & "C:\Path\To\fb2-book-organizer\OrganizeBooks.ps1"
   ```

> **Note:** Moving files to the Recycle Bin without native OS popup prompts relies on the built-in Windows `Microsoft.VisualBasic` assembly. No external module installations or third-party dependencies are required.
