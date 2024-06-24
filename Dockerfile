FROM mcr.microsoft.com/powershell

WORKDIR /scripts

COPY . .

RUN pwsh -Command "Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser"

ENTRYPOINT ["pwsh"]