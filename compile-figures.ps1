<#
.SYNOPSIS
批量将 ./figures/mmd/ 下的 .mmd 文件渲染为 PDF，
.DESCRIPTION
依赖 mermaid-cli (mmdc)，需提前全局安装
#>

# 定义目录：
$sourceDir = "./figures/mmd"  # .mmd 源文件目录
$targetDir = "./figures/mmd"  # PDF 输出目标目录

# Docker 镜像名称（根据实际镜像名称修改）
$dockerImage = "minlag/mermaid-cli"

# 1. 检查源目录是否存在
if (-not (Test-Path -Path $sourceDir -PathType Container)) {
    Write-Error "错误：源目录 $sourceDir 不存在，请先创建该目录并放入 .mmd 文件！"
    exit 1
}

# 2. 检查目标目录是否存在（不存在则自动创建）
if (-not (Test-Path -Path $targetDir -PathType Container)) {
    Write-Host "目标目录 $targetDir 不存在，正在自动创建..."
    New-Item -Path $targetDir -ItemType Directory | Out-Null
}

# 3. 检查 Docker 是否可用
if (-not (Get-Command -Name docker -ErrorAction SilentlyContinue)) {
    Write-Error "错误：未找到 docker 命令，请先安装并启动 Docker Desktop！"
    exit 1
}

# 4. 将相对路径转换为绝对路径（Docker 需要）
$sourceDirAbs = (Resolve-Path -Path $sourceDir).Path
$targetDirAbs = (Resolve-Path -Path $targetDir).Path

# 4. 遍历源目录下所有 .mmd 文件并渲染
Get-ChildItem -Path $sourceDir -Filter "*.mmd" | ForEach-Object {
    # 获取文件基本信息
    $inputFile = $_.FullName          # 完整输入路径（如 ./figures/mmd/test.mmd）
    $fileName = $_.BaseName           # 文件名（不含后缀，如 test）
    # 输出路径：目标目录 + 原文件名.pdf
    $outputFile = Join-Path -Path $targetDir -ChildPath "$fileName.pdf"

    Write-Host "正在渲染：$inputFile -> $outputFile"

    # 使用 Docker 运行 mermaid-cli 渲染
    # 采用参数数组形式避免强转义和路径空格问题
    $dockerArgs = @(
        "run", "--rm",
        "-v", "${sourceDirAbs}:/input:ro",
        "-v", "${targetDirAbs}:/output",
        $dockerImage,
        "-i", "/input/$fileName.mmd",
        "-o", "/output/$fileName.pdf",
        "-f",             # --pdfFit 的简写，Scale PDF to fit chart
        "-w", "1200"
    )

    Write-Host "执行命令: docker $dockerArgs"
    & docker @dockerArgs

    # 检查渲染是否成功
    if (Test-Path -Path $outputFile) {
        Write-Host "Success: $outputFile`n"
    } else {
        Write-Error "Failed: $inputFile 渲染失败！"
    }
}

Write-Host "Done! mmd files converted."

# 5. figures/code 目录下的 .tex 文件转为 PDF
$codeDir = "./figures/code"
if (Test-Path -Path $codeDir -PathType Container) {
    Write-Host "`n正在处理 figures/code 目录下的 .tex 文件..."
    
    # 检查 xelatex 是否可用
    if (Get-Command -Name xelatex -ErrorAction SilentlyContinue) {
        Get-ChildItem -Path $codeDir -Filter "*.tex" | ForEach-Object {
            $texFile = $_.FullName
            $baseName = $_.BaseName
            $pdfFile = Join-Path -Path $codeDir -ChildPath "$baseName.pdf"
            
            Write-Host "正在编译：$texFile -> $pdfFile"
            
            # 切换到文件所在目录进行编译
            Push-Location $_.Directory.FullName
            
            # 使用 xelatex 编译，启用 shell-escape (用于 minted)
            $latexArgs = @(
                "-shell-escape",
                "-interaction=nonstopmode",
                "$baseName.tex"
            )

            # 执行 xelatex，忽略标准输出以减少干扰，保留错误流
            & xelatex @latexArgs | Out-Null

            if ($LASTEXITCODE -eq 0 -and (Test-Path -Path "$baseName.pdf")) {
                Write-Host "Success: $pdfFile"
                # 清理辅助文件 (保留 .tex 和 .pdf)
                Get-ChildItem -Filter "$baseName.*" | Where-Object { $_.Extension -ne ".tex" -and $_.Extension -ne ".pdf" } | Remove-Item -Force
                # 清理 _minted-* 目录
                if (Test-Path "_minted-$baseName") { Remove-Item "_minted-$baseName" -Recurse -Force }
            } else {
                Write-Error "Failed: $texFile 编译失败！"
            }
            Pop-Location
        }
    } else {
        Write-Warning "警告：未找到 xelatex 命令，无法转换 code 目录下的 .tex 文件。"
    }
}

# 6. figures/test-result 目录下的 CSV 绘制为 PDF
$testResultDir = "./figures/test-result"
$plotScript = Join-Path -Path $testResultDir -ChildPath "plot_throughput_bar.py"
if (Test-Path -Path $plotScript -PathType Leaf) {
    Write-Host "`n正在处理 figures/test-result 目录下的吞吐量柱状图..."

    if (Get-Command -Name python -ErrorAction SilentlyContinue) {
        $testResultDirAbs = (Resolve-Path -Path $testResultDir).Path
        $mplConfigDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "master-thesis-mplconfig"
        if (-not (Test-Path -Path $mplConfigDir -PathType Container)) {
            New-Item -Path $mplConfigDir -ItemType Directory | Out-Null
        }

        Push-Location $testResultDirAbs
        $env:MPLCONFIGDIR = $mplConfigDir
        & python "plot_throughput_bar.py"

        if ($LASTEXITCODE -eq 0) {
            Write-Host "Success: test-result figures generated."
        } else {
            Write-Error "Failed: test-result figures generation failed!"
        }
        Pop-Location
    } else {
        Write-Warning "警告：未找到 python 命令，无法生成 test-result 目录下的 PDF 图。"
    }
}

Write-Host "Done! 所有任务已完成。"


