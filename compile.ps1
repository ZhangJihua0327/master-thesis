<#
.SYNOPSIS
Build figures and compile the thesis PDF.
.DESCRIPTION
- Render Mermaid diagrams under figures/mmd to PDF.
- Compile standalone TeX files under figures/code to PDF.
- Generate benchmark charts under figures/test-result.
- Compile the main thesis document to PDF.
#>

param(
    [string]$Target = $null,
    [string]$OutputName = $null
)

$ErrorActionPreference = "Stop"
if ($null -ne (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue)) {
    $PSNativeCommandUseErrorActionPreference = $false
}

$rootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $rootDir

$sourceDir = "./figures/mmd"
$targetDir = "./figures/mmd"
$mermaidCanvasWidth = "1800"
$dockerImage = "minlag/mermaid-cli"

$codeDir = "./figures/code"
$testResultDir = "./figures/test-result"
$plotScripts = @(
    "plot_throughput_bar.py",
    "plot_abort_rate_bar.py",
    "plot_throughput_gain_bar.py",
    "plot_stress_test.py"
)
$thesisMain = "zhangjihua-master-thesis.tex"
$thesisPdf = "zhangjihua-master-thesis.pdf"

function Test-Tool($name) {
    return $null -ne (Get-Command -Name $name -ErrorAction SilentlyContinue)
}

function Get-PythonCommand {
    if (Test-Tool "python") {
        return "python"
    }

    if (Test-Tool "py") {
        return "py"
    }

    return $null
}

function Invoke-MermaidCompilation {
    param(
        [string]$SingleFile = $null
    )

    if (-not (Test-Path -Path $sourceDir -PathType Container)) {
        Write-Warning "Skip Mermaid compilation: directory $sourceDir does not exist."
        return
    }

    if (-not (Test-Tool "docker")) {
        Write-Warning "Skip Mermaid compilation: docker not found."
        return
    }

    $sourceDirAbs = (Resolve-Path -Path $sourceDir).Path
    $targetDirAbs = (Resolve-Path -Path $targetDir).Path

    $files = Get-ChildItem -Path $sourceDir -Filter "*.mmd"
    if ($SingleFile) {
        $singleBase = [System.IO.Path]::GetFileNameWithoutExtension($SingleFile)
        $matched = $files | Where-Object { $_.BaseName -eq $singleBase }
        if (-not $matched) {
            throw "Mermaid source file not found: $SingleFile"
        }
        $files = $matched
    }

    Write-Host "Compiling Mermaid diagrams..."

    $files | ForEach-Object {
        $inputFile = $_.FullName
        $fileName = $_.BaseName
        $outputFile = Join-Path -Path $targetDir -ChildPath "$fileName.pdf"
        $tempOutputFile = Join-Path -Path $targetDir -ChildPath "$fileName.tmp.pdf"

        if (Test-Path -Path $tempOutputFile) {
            Remove-Item -Path $tempOutputFile -Force
        }

        Write-Host "Rendering: $inputFile -> $outputFile"

        $dockerArgs = @(
            "run", "--rm",
            "-v", "${sourceDirAbs}:/input:ro",
            "-v", "${targetDirAbs}:/output",
            $dockerImage,
            "-i", "/input/$fileName.mmd",
            "-o", "/output/$fileName.tmp.pdf",
            "-f",
            "-w", $mermaidCanvasWidth
        )

        & docker @dockerArgs

        if ($LASTEXITCODE -eq 0 -and (Test-Path -Path $tempOutputFile)) {
            Move-Item -Path $tempOutputFile -Destination $outputFile -Force
            Write-Host "Success: $outputFile"
        } else {
            if (Test-Path -Path $tempOutputFile) {
                Remove-Item -Path $tempOutputFile -Force
            }
            Write-Warning "Mermaid render failed, keeping existing file if present: $outputFile"
        }
    }
}

function Invoke-CodeFigureCompilation {
    if (-not (Test-Path -Path $codeDir -PathType Container)) {
        return
    }

    Write-Host "`nCompiling figures/code standalone TeX files..."

    if (-not (Test-Tool "xelatex")) {
        Write-Warning "Skip code figure compilation: xelatex not found."
        return
    }

    Get-ChildItem -Path $codeDir -Filter "*.tex" | ForEach-Object {
        $texFile = $_.FullName
        $baseName = $_.BaseName
        $pdfFile = Join-Path -Path $codeDir -ChildPath "$baseName.pdf"

        Write-Host "Compiling: $texFile -> $pdfFile"
        Push-Location $_.Directory.FullName

        try {
            $latexArgs = @(
                "-shell-escape",
                "-interaction=nonstopmode",
                "$baseName.tex"
            )

            & xelatex @latexArgs | Out-Null

            if ($LASTEXITCODE -eq 0 -and (Test-Path -Path "$baseName.pdf")) {
                Write-Host "Success: $pdfFile"
                Get-ChildItem -Filter "$baseName.*" | Where-Object { $_.Extension -ne ".tex" -and $_.Extension -ne ".pdf" } | Remove-Item -Force
                if (Test-Path "_minted-$baseName") {
                    Remove-Item "_minted-$baseName" -Recurse -Force
                }
            } else {
                throw "Code figure compilation failed: $texFile"
            }
        } finally {
            Pop-Location
        }
    }
}

function Invoke-TestResultCompilation {
    $availableScripts = @($plotScripts | Where-Object {
        Test-Path -Path (Join-Path -Path $testResultDir -ChildPath $_) -PathType Leaf
    })

    if ($availableScripts.Count -eq 0) {
        return
    }

    Write-Host "`nGenerating benchmark charts..."

    $pythonCmd = Get-PythonCommand
    if (-not $pythonCmd) {
        Write-Warning "Skip benchmark chart generation: neither python nor py was found."
        return
    }

    $testResultDirAbs = (Resolve-Path -Path $testResultDir).Path
    $mplConfigDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "master-thesis-mplconfig"
    if (-not (Test-Path -Path $mplConfigDir -PathType Container)) {
        New-Item -Path $mplConfigDir -ItemType Directory | Out-Null
    }

    Push-Location $testResultDirAbs
    try {
        $env:MPLCONFIGDIR = $mplConfigDir
        foreach ($script in $availableScripts) {
            & $pythonCmd $script

            if ($LASTEXITCODE -ne 0) {
                throw "Benchmark chart generation failed: $script"
            }
        }

        Write-Host "Success: benchmark charts generated."
    } finally {
        Pop-Location
    }
}

function Invoke-ThesisCompilation {
    param(
        [string]$DesiredOutputName = $null
    )

    Write-Host "`nCompiling thesis PDF..."

    if (-not (Test-Path -Path $thesisMain -PathType Leaf)) {
        throw "Main thesis file not found: $thesisMain"
    }

    if (Test-Tool "latexmk") {
        $latexmkArgs = @(
            "-xelatex",
            "-shell-escape",
            "-interaction=nonstopmode",
            "-file-line-error",
            $thesisMain
        )

        & latexmk @latexmkArgs

        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -Path $thesisPdf)) {
            throw "latexmk failed to compile the thesis."
        }

        if ($DesiredOutputName) {
            $outputFileName = [System.IO.Path]::GetFileName($DesiredOutputName)
            if (-not $outputFileName.ToLower().EndsWith('.pdf')) {
                $outputFileName += '.pdf'
            }
            $outputPath = Join-Path -Path $rootDir -ChildPath $outputFileName
            if ((Test-Path -Path $outputPath) -and ($outputPath -ne (Join-Path -Path $rootDir -ChildPath $thesisPdf))) {
                Remove-Item -Path $outputPath -Force
            }
            Move-Item -Path (Join-Path -Path $rootDir -ChildPath $thesisPdf) -Destination $outputPath -Force
            Write-Host "Success: $outputPath"
            return
        }

        Write-Host "Success: $thesisPdf"
        return
    }

    if (-not (Test-Tool "xelatex")) {
        throw "Neither latexmk nor xelatex is available."
    }

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($thesisMain)
    $xelatexArgs = @(
        "-shell-escape",
        "-interaction=nonstopmode",
        $thesisMain
    )

    & xelatex @xelatexArgs
    if ($LASTEXITCODE -ne 0) {
        throw "The first xelatex pass failed."
    }

    if (Test-Tool "biber") {
        & biber $baseName
        if ($LASTEXITCODE -ne 0) {
            throw "biber failed."
        }
    }

    & xelatex @xelatexArgs
    if ($LASTEXITCODE -ne 0) {
        throw "The second xelatex pass failed."
    }

    & xelatex @xelatexArgs
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -Path $thesisPdf)) {
        throw "Failed to generate the thesis PDF."
    }

    Write-Host "Success: $thesisPdf"
}

if ($Target -and -not $OutputName) {
    Invoke-MermaidCompilation -SingleFile $Target
    Write-Host "`nDone! Single Mermaid diagram compiled."
    return
}

if ($Target -and $OutputName) {
    Invoke-MermaidCompilation
    Invoke-CodeFigureCompilation
    Invoke-TestResultCompilation
    Invoke-ThesisCompilation -DesiredOutputName $OutputName
    Write-Host "`nDone! Project compiled to $OutputName."
    return
}

# Default: compile only figures, not the full thesis PDF
Invoke-MermaidCompilation
Invoke-CodeFigureCompilation
Invoke-TestResultCompilation

Write-Host "`nDone! Figures are up to date. Use '.\compile.ps1 project <outputname>' to compile the full thesis PDF."
