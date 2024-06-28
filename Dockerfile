FROM mcr.microsoft.com/powershell:latest

WORKDIR /mnt/tiny_power_buddy

RUN apt-get update && \
    apt-get install -y git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN pwsh -Command "Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser"

COPY . .

ENTRYPOINT ["pwsh"]