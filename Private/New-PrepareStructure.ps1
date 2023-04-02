﻿function New-PrepareStructure {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary]$Configuration = [ordered] @{},
        [scriptblock] $Settings,
        [string] $PathToProject
    )
    # Lets precreate structure if it's not available
    if (-not $Configuration.Information) {
        $Configuration.Information = [ordered] @{}
    }
    if (-not $Configuration.Information.Manifest) {
        $Configuration.Information.Manifest = [ordered] @{}
    }
    # This deals with OneDrive redirection or similar
    if (-not $Configuration.Information.DirectoryModulesCore) {
        $Configuration.Information.DirectoryModulesCore = "$([Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments))\PowerShell\Modules"
    }
    # This deals with OneDrive redirection or similar
    if (-not $Configuration.Information.DirectoryModules) {
        $Configuration.Information.DirectoryModules = "$([Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments))\WindowsPowerShell\Modules"
    }
    if ($ModuleName) {
        $Configuration.Information.ModuleName = $ModuleName
    }
    if ($ExcludeFromPackage) {
        $Configuration.Information.Exclude = $ExcludeFromPackage
    }
    if ($IncludeRoot) {
        $Configuration.Information.IncludeRoot = $IncludeRoot
    }
    if ($IncludePS1) {
        $Configuration.Information.IncludePS1 = $IncludePS1
    }
    if ($IncludeAll) {
        $Configuration.Information.IncludeAll = $IncludeAll
    }
    if ($IncludeCustomCode) {
        $Configuration.Information.IncludeCustomCode = $IncludeCustomCode
    }
    if ($IncludeToArray) {
        $Configuration.Information.IncludeToArray = $IncludeToArray
    }
    if ($LibrariesCore) {
        $Configuration.Information.LibrariesCore = $LibrariesCore
    }
    if ($LibrariesDefault) {
        $Configuration.Information.LibrariesDefault = $LibrariesDefault
    }
    if ($LibrariesStandard) {
        $Configuration.Information.LibrariesStandard = $LibrariesStandard
    }
    if ($DirectoryProjects) {
        $Configuration.Information.DirectoryProjects = $Path
    }
    if ($FunctionsToExportFolder) {
        $Configuration.Information.FunctionsToExport = $FunctionsToExportFolder
    }
    if ($AliasesToExportFolder) {
        $Configuration.Information.AliasesToExport = $AliasesToExportFolder
    }
    Write-TextWithTime -Text "Reading configuration" {
        if ($Settings) {
            $ExecutedSettings = & $Settings
            foreach ($Setting in $ExecutedSettings) {
                if ($Setting.Type -eq 'RequiredModule') {
                    if ($Configuration.Information.Manifest.RequiredModules -isnot [System.Collections.Generic.List[System.Object]]) {
                        $Configuration.Information.Manifest.RequiredModules = [System.Collections.Generic.List[System.Object]]::new()
                    }
                    $Configuration.Information.Manifest.RequiredModules.Add($Setting.Configuration)
                } elseif ($Setting.Type -eq 'ExternalModule') {
                    if ($Configuration.Information.Manifest.ExternalModuleDependencies -isnot [System.Collections.Generic.List[System.Object]]) {
                        $Configuration.Information.Manifest.ExternalModuleDependencies = [System.Collections.Generic.List[System.Object]]::new()
                    }
                    $Configuration.Information.Manifest.ExternalModuleDependencies.Add($Setting.Configuration)
                } elseif ($Setting.Type -eq 'Manifest') {
                    foreach ($Key in $Setting.Configuration.Keys) {
                        $Configuration.Information.Manifest[$Key] = $Setting.Configuration[$Key]
                    }
                } elseif ($Setting.Type -eq 'Information') {
                    foreach ($Key in $Setting.Configuration.Keys) {
                        $Configuration.Information[$Key] = $Setting.Configuration[$Key]
                    }
                } elseif ($Setting.Type -eq 'Formatting') {
                    foreach ($Key in $Setting.Options.Keys) {
                        if (-not $Configuration.Options[$Key]) {
                            $Configuration.Options[$Key] = @{}
                        }
                        foreach ($Entry in $Setting.Options[$Key].Keys) {
                            $Configuration.Options[$Key][$Entry] = $Setting.Options[$Key][$Entry]
                        }
                    }
                }
            }
        }
    } -PreAppend Information

    # We build module or do other stuff with it
    if ($Configuration.Steps.BuildModule.Enable -or
        $Configuration.Steps.BuildModule.EnableDesktop -or
        $Configuration.Steps.BuildModule.EnableCore -or
        $Configuration.Steps.BuildDocumentation -eq $true -or
        $Configuration.Steps.BuildLibraries.Enable -or
        $Configuration.Steps.PublishModule.Enable -or
        $Configuration.Steps.PublishModule.Enabled) {
        $Success = Start-ModuleBuilding -Configuration $Configuration -PathToProject $PathToProject
        if ($Success -eq $false) {
            return
        }
    }
}