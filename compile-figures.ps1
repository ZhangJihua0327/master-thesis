<#
.SYNOPSIS
批量将 ./figures/mmd/ 下的 .mmd 文件渲染为 PDF，输出到 ./figures/（文件名格式：原文件名_m.pdf）
.DESCRIPTION
依赖 mermaid-cli (mmdc)，需提前全局安装
#>

# 定义目录：修正源目录为 ./figures/mmd，目标目录为 ./figures
$sourceDir = "./figures/mmd"  # .mmd 源文件目录（你的要求）
$targetDir = "./figures"      # PDF 输出目标目录（你的要求）

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
    # 输出路径：目标目录 + 原文件名_m.pdf（如 ./figures/test_m.pdf）
    $outputFile = Join-Path -Path $targetDir -ChildPath "$fileName`_m.pdf"

    Write-Host "正在渲染：$inputFile -> $outputFile"

    # 使用 Docker 运行 mermaid-cli 渲染
    # 采用参数数组形式避免强转义和路径空格问题
    $dockerArgs = @(
        "run", "--rm",
        "-v", "${sourceDirAbs}:/input:ro",
        "-v", "${targetDirAbs}:/output",
        $dockerImage,
        "-i", "/input/$fileName.mmd",
        "-o", "/output/$fileName`_m.pdf",
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

Write-Host "Done! 所有 PDF 文件已输出到 $targetDir 目录"
