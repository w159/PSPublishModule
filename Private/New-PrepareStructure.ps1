﻿function New-PrepareStructure {
    [CmdletBinding()]
    param(
        [System.Collections.IDictionary]$Configuration,
        [scriptblock] $Settings,
        [string] $PathToProject,
        [string] $ModuleName
    )
    # Lets precreate structure if it's not available
    if (-not $Configuration) {
        $Configuration = [ordered] @{}
    }
    if (-not $Configuration.Information) {
        $Configuration.Information = [ordered] @{}
    }
    if (-not $Configuration.Information.Manifest) {
        # if it's not provided, we try to get it from PSD1 file
        $PathToPSD1 = [io.path]::Combine($PathToProject, $ModuleName + '.psd1')
        if (Test-Path -LiteralPath $PathToPSD1) {
            try {
                $Configuration.Information.Manifest = Import-PowerShellDataFile -Path $PathToPSD1 -ErrorAction Stop
                # lets reset whatever is in PSD1 that we load
                $Configuration.Information.Manifest.RequiredModules = $null
            } catch {
                Write-Text "[-] Reading $PathToPSD1 failed. Error: $($_.Exception.Message)" -Color Red
                return $false
            }
        } else {
            $Configuration.Information.Manifest = [ordered] @{}
        }
    }
    # This deals with OneDrive redirection or similar
    if (-not $Configuration.Information.DirectoryModulesCore) {
        $Configuration.Information.DirectoryModulesCore = "$([Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments))\PowerShell\Modules"
    }
    # This deals with OneDrive redirection or similar
    if (-not $Configuration.Information.DirectoryModules) {
        $Configuration.Information.DirectoryModules = "$([Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments))\WindowsPowerShell\Modules"
    }
    # This is to use within module between different stages
    # kind of temporary settings storage
    if (-not $Configuration.CurrentSettings) {
        $Configuration.CurrentSettings = [ordered] @{}
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
    if (-not $Configuration.Options) {
        $Configuration.Options = [ordered] @{}
    }
    if (-not $Configuration.Options.Merge) {
        $Configuration.Options.Merge = [ordered] @{}
    }
    if (-not $Configuration.Options.Merge.Integrate) {
        $Configuration.Options.Merge.Integrate = [ordered] @{}
    }
    if (-not $Configuration.Options.Standard) {
        $Configuration.Options.Standard = [ordered] @{}
    }
    if (-not $Configuration.Options.Signing) {
        $Configuration.Options.Signing = [ordered] @{}
    }
    if (-not $Configuration.Steps) {
        $Configuration.Steps = [ordered] @{}
    }
    if (-not $Configuration.Steps.PublishModule) {
        $Configuration.Steps.PublishModule = [ordered] @{}
    }
    if (-not $Configuration.Steps.ImportModules) {
        $Configuration.Steps.ImportModules = [ordered] @{}
    }
    if (-not $Configuration.Steps.BuildModule) {
        $Configuration.Steps.BuildModule = [ordered] @{}
    }
    if (-not $Configuration.Steps.BuildModule.Releases) {
        $Configuration.Steps.BuildModule.Releases = [ordered] @{}
    }
    if (-not $Configuration.Steps.BuildModule.ReleasesUnpacked) {
        $Configuration.Steps.BuildModule.ReleasesUnpacked = [ordered] @{}
    }
    if (-not $Configuration.Steps.BuildLibraries) {
        $Configuration.Steps.BuildLibraries = [ordered] @{}
    }
    if (-not $Configuration.Information.Manifest.CommandModuleDependencies) {
        $Configuration.Information.Manifest.CommandModuleDependencies = [ordered] @{}
    }
    if (-not $Configuration.Steps.BuildModule.Artefacts) {
        $Configuration.Steps.BuildModule.Artefacts = [System.Collections.Generic.List[System.Collections.IDictionary]]::new()
    }
    # Fix required fields:
    $Configuration.Information.Manifest.RootModule = "$($ModuleName).psm1"
    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry,
    # use an empty array if there are no cmdlets to export.
    $Configuration.Information.Manifest.CmdletsToExport = @()
    # Variables to export from this module
    #$Configuration.Information.Manifest.VariablesToExport = @()

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
                } elseif ($Setting.Type -eq 'ApprovedModule') {
                    if ($Configuration.Options.Merge.Integrate.ApprovedModules -isnot [System.Collections.Generic.List[System.Object]]) {
                        $Configuration.Options.Merge.Integrate.ApprovedModules = [System.Collections.Generic.List[System.Object]]::new()
                    }
                    $Configuration.Options.Merge.Integrate.ApprovedModules.Add($Setting.Configuration)
                } elseif ($Setting.Type -eq 'ModuleSkip') {
                    $Configuration.Options.Merge.ModuleSkip = $Setting.Configuration
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
                            $Configuration.Options[$Key] = [ordered] @{}
                        }
                        foreach ($Entry in $Setting.Options[$Key].Keys) {
                            $Configuration.Options[$Key][$Entry] = $Setting.Options[$Key][$Entry]
                        }
                    }
                } elseif ($Setting.Type -eq 'Command') {
                    $Configuration.Information.Manifest.CommandModuleDependencies[$Setting.Configuration.ModuleName] = @($Setting.Configuration.CommandName)
                } elseif ($Setting.Type -eq 'Documentation') {
                    $Configuration.Options.Documentation = $Setting.Configuration
                } elseif ($Setting.Type -eq 'BuildDocumentation') {
                    $Configuration.Steps.BuildDocumentation = $Setting.Configuration
                } elseif ($Setting.Type -eq 'GitHub') {
                    $Configuration.Options.GitHub = $Setting.Configuration.GitHub
                } elseif ($Setting.Type -eq 'PowerShellGallery') {
                    $Configuration.Options.PowerShellGallery = $Setting.Configuration.PowerShellGallery
                } elseif ($Setting.Type -eq 'PowerShellGalleryPublishing') {
                    foreach ($Key in $Setting.PublishModule.Keys) {
                        $Configuration.Steps.PublishModule[$Key] = $Setting.PublishModule[$Key]
                    }
                } elseif ($Setting.Type -eq 'TestsBeforeMerge') {
                    $Configuration.Options.TestsBeforeMerge = $Setting.Configuration
                } elseif ($Setting.Type -eq 'TestsAfterMerge') {
                    $Configuration.Options.TestsAfterMerge = $Setting.Configuration
                } elseif ($Setting.Type -eq 'GitHubPublishing') {
                    foreach ($Key in $Setting.PublishModule.Keys) {
                        $Configuration.Steps.PublishModule[$Key] = $Setting.PublishModule[$Key]
                    }
                } elseif ($Setting.Type -eq 'ImportModules') {
                    foreach ($Key in $Setting.ImportModules.Keys) {
                        $Configuration.Steps.ImportModules[$Key] = $Setting.ImportModules[$Key]
                    }
                } elseif ($Setting.Type -eq 'Releases') {
                    #foreach ($Key in $Setting.Releases.Keys) {
                    #    $Configuration.Steps.BuildModule['Releases'][$Key] = $Setting.Releases[$Key]
                    #}
                } elseif ($Setting.Type -in 'Unpacked', 'Packed', 'Script', 'ScriptPacked') {
                    $Configuration.Steps.BuildModule.Artefacts.Add($Setting.Configuration)

                    #foreach ($Key in $Setting.ReleasesUnpacked.Keys) {
                    # foreach ($Key in $Setting.ReleasesUnpacked.Keys) {
                    #     if ($Setting.ReleasesUnpacked[$Key] -is [System.Collections.IDictionary]) {
                    #         foreach ($Entry in $Setting.ReleasesUnpacked[$Key].Keys) {
                    #             if (-not $Configuration.Steps.BuildModule['ReleasesUnpacked'][$Key]) {
                    #                 $Configuration.Steps.BuildModule['ReleasesUnpacked'][$Key] = [ordered] @{}
                    #             }
                    #             $Configuration.Steps.BuildModule['ReleasesUnpacked'][$Key][$Entry] = $Setting.ReleasesUnpacked[$Key][$Entry]
                    #         }
                    #     } else {
                    #         $Configuration.Steps.BuildModule['ReleasesUnpacked'][$Key] = $Setting.ReleasesUnpacked[$Key]
                    #     }
                    # }
                    #}
                } elseif ($Setting.Type -eq 'Build') {
                    foreach ($Key in $Setting.BuildModule.Keys) {
                        $Configuration.Steps.BuildModule[$Key] = $Setting.BuildModule[$Key]
                    }
                } elseif ($Setting.Type -eq 'BuildLibraries') {
                    foreach ($Key in $Setting.BuildLibraries.Keys) {
                        $Configuration.Steps.BuildLibraries[$Key] = $Setting.BuildLibraries[$Key]
                    }
                } elseif ($Setting.Type -eq 'Options') {
                    foreach ($Key in $Setting.Options.Keys) {
                        if (-not $Configuration.Options[$Key]) {
                            $Configuration.Options[$Key] = [ordered] @{}
                        }
                        foreach ($Entry in $Setting.Options[$Key].Keys) {
                            $Configuration.Options[$Key][$Entry] = $Setting.Options[$Key][$Entry]
                        }
                    }
                }
            }
        }
    } -PreAppend Information

    # lets set some defaults
    if (-not $Configuration.Options.Merge.Sort) {
        $Configuration.Options.Merge.Sort = 'None'
    }
    if (-not $Configuration.Options.Standard.Sort) {
        $Configuration.Options.Standard.Sort = 'None'
    }

    # We build module or do other stuff with it
    $Success = Start-ModuleBuilding -Configuration $Configuration -PathToProject $PathToProject
    if ($Success -eq $false) {
        return $false
    }
}