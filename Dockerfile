FROM mcr.microsoft.com/powershell

WORKDIR /mnt/tiny_power_buddy

RUN pwsh -Command "Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser"

COPY . .

ENTRYPOINT ["pwsh"]