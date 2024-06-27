# Frequently Used Commands

## Install PSScriptAnalyzer for static code analysis 
```
$ Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
```

## Analyze PowerShell Script
```
Invoke-ScriptAnalyzer -Path .\SCRIPT_NAME.ps1
```

## Docker
```
$ docker-compose images
$ docker-compose ps
$ docker-compose build --no-cache
$ docker-compose up -d
$ docker-compose exec tiny_power_buddy pwsh
$ docker-compose stop
$ docker-compose down --rmi all
```