if (Test-Path C:\WindowsBuilder)
{
    Write-Error 'A copy of WindowsBuilder is already installed at "C:\WindowsBuilder". Remove the folder and try again.'
}

if (Test-Path $env:TEMP\windowsbuilder.zip)
{
    del $env:TEMP\windowsbuilder.zip
}

wget 'https://github.com/buildcenter/WindowsBuilder/archive/v1.0.0.zip' -UseBasicParsing -OutFile $env:TEMP\windowsbuilder.zip
Expand-Archive -Path $env:TEMP\windowsbuilder.zip -DestinationPath C:\
cd C:\WindowsBuilder
