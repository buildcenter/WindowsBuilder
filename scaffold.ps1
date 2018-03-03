if (Test-Path C:\WindowsBuilder)
{
    throw 'A copy of WindowsBuilder is already installed at "C:\WindowsBuilder". Remove the folder and try again.'
}

if (Test-Path $env:TEMP\windowsbuilder.zip)
{
    del $env:TEMP\windowsbuilder.zip
}

wget https://github.com/buildcenter/WindowsBuilder/releases/download/v1.0.0/WindowsBuilder.zip -OutFile $env:TEMP\windowsbuilder.zip -UseBasicParsing
md C:\WindowsBuilder
cd C:\WindowsBuilder
Expand-Archive -Path $env:TEMP\windowsbuilder.zip -DestinationPath .\
