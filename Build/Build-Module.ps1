﻿# please notice I may be using PSM1 here (not always), as the module may not be built or PSD1 may be broken
# since PSD1 is not required for proper rebuilding, we use PSM1 for this module only
# most modules should be run via PSD1 or by it's name (which in the background uses PD1)

# This version is used for GitHub Actions and is used to build the module

# We need to rmeove library before we start, as it may contain old files, which will be in use once PSD1 loads
# This is only required for PSPublisModule, as it's the only module that is being built by itself
Remove-Item -Path "C:\Support\GitHub\PSPublishModule\Lib" -Recurse -Force -ErrorAction SilentlyContinue

Import-Module ([io.path]::Combine($PSScriptRoot, '..', 'PSPublishModule.psd1')) -Force

Build-Module -ModuleName 'PSPublishModule' {
    # Usual defaults as per standard module
    $Manifest = [ordered] @{
        ModuleVersion          = '2.0.X'
        #PreReleaseTag          = 'Preview5'
        CompatiblePSEditions   = @('Desktop', 'Core')
        GUID                   = 'eb76426a-1992-40a5-82cd-6480f883ef4d'
        Author                 = 'Przemyslaw Klys'
        CompanyName            = 'Evotec'
        Copyright              = "(c) 2011 - $((Get-Date).Year) Przemyslaw Klys @ Evotec. All rights reserved."
        Description            = 'Simple project allowing preparing, managing, building and publishing modules to PowerShellGallery'
        PowerShellVersion      = '5.1'
        Tags                   = @('Windows', 'MacOS', 'Linux', 'Build', 'Module')
        IconUri                = 'https://evotec.xyz/wp-content/uploads/2019/02/PSPublishModule.png'
        ProjectUri             = 'https://github.com/EvotecIT/PSPublishModule'
        DotNetFrameworkVersion = '4.5.2'
    }
    New-ConfigurationManifest @Manifest

    # Add standard module dependencies (directly, but can be used with loop as well)
    # New-ConfigurationModule -Type RequiredModule -Name 'platyPS', 'HelpOut' -Guid 'Auto' -Version 'Latest'
    New-ConfigurationModule -Type RequiredModule -Name 'powershellget' -Guid 'Auto' -Version 'Latest'
    New-ConfigurationModule -Type RequiredModule -Name 'PSScriptAnalyzer' -Guid 'Auto' -Version 'Latest'
    New-ConfigurationModule -Type RequiredModule -Name 'Pester' -Version Auto -Guid Auto

    # Add external module dependencies, using loop for simplicity
    New-ConfigurationModule -Type ExternalModule -Name @(
        'Microsoft.PowerShell.Utility', 'Microsoft.PowerShell.Archive', 'Microsoft.PowerShell.Management', 'Microsoft.PowerShell.Security'
    )

    # Add approved modules, that can be used as a dependency, but only when specific function from those modules is used
    # And on that time only that function and dependant functions will be copied over
    # Keep in mind it has it's limits when "copying" functions such as it should not depend on DLLs or other external files
    New-ConfigurationModule -Type ApprovedModule -Name 'PSSharedGoods', 'PSWriteColor', 'Connectimo', 'PSUnifi', 'PSWebToolbox', 'PSMyPassword'

    New-ConfigurationModuleSkip -IgnoreModuleName 'PKI', 'OpenAuthenticode', 'platyPS', 'HelpOut' -IgnoreFunctionName @(
        # ignore functions from OpenAuthenticode module when used during linux/macos build
        'Set-OpenAuthenticodeSignature'
        'Get-OpenAuthenticodeSignature'
        # ignore functions from Microsoft.PowerShell.Security, as those are not on linux/macos
        'Get-AuthenticodeSignature'
        'Set-AuthenticodeSignature'
        # ignore functions from PKI module when used during linux/macos build
        #'Import-PfxCertificate'
        'Save-MarkdownHelp'
        'New-MarkdownHelp'
        'Update-MarkdownHelpModule'
        # seems to be windows only
        'New-FileCatalog'
    )


    $ConfigurationFormat = [ordered] @{
        RemoveComments                              = $false

        PlaceOpenBraceEnable                        = $true
        PlaceOpenBraceOnSameLine                    = $true
        PlaceOpenBraceNewLineAfter                  = $true
        PlaceOpenBraceIgnoreOneLineBlock            = $false

        PlaceCloseBraceEnable                       = $true
        PlaceCloseBraceNewLineAfter                 = $false
        PlaceCloseBraceIgnoreOneLineBlock           = $false
        PlaceCloseBraceNoEmptyLineBefore            = $true

        UseConsistentIndentationEnable              = $true
        UseConsistentIndentationKind                = 'space'
        UseConsistentIndentationPipelineIndentation = 'IncreaseIndentationAfterEveryPipeline'
        UseConsistentIndentationIndentationSize     = 4

        UseConsistentWhitespaceEnable               = $true
        UseConsistentWhitespaceCheckInnerBrace      = $true
        UseConsistentWhitespaceCheckOpenBrace       = $true
        UseConsistentWhitespaceCheckOpenParen       = $true
        UseConsistentWhitespaceCheckOperator        = $true
        UseConsistentWhitespaceCheckPipe            = $true
        UseConsistentWhitespaceCheckSeparator       = $true

        AlignAssignmentStatementEnable              = $true
        AlignAssignmentStatementCheckHashtable      = $true

        UseCorrectCasingEnable                      = $true
    }
    # format PSD1 and PSM1 files when merging into a single file
    # enable formatting is not required as Configuration is provided
    New-ConfigurationFormat -ApplyTo 'OnMergePSM1', 'OnMergePSD1' -Sort None @ConfigurationFormat
    # format PSD1 and PSM1 files within the module
    # enable formatting is required to make sure that formatting is applied (with default settings)
    New-ConfigurationFormat -ApplyTo 'DefaultPSD1', 'DefaultPSM1' -EnableFormatting -Sort None
    # when creating PSD1 use special style without comments and with only required parameters
    New-ConfigurationFormat -ApplyTo 'DefaultPSD1', 'OnMergePSD1' -PSD1Style 'Minimal'

    # configuration for documentation, at the same time it enables documentation processing
    New-ConfigurationDocumentation -Enable:$true -StartClean -UpdateWhenNew -PathReadme ([io.path]::Combine('Docs', 'Readme.md')) -Path 'Docs' -Tool HelpOut

    New-ConfigurationImportModule -ImportSelf

    $newConfigurationBuildSplat = @{
        Enable                            = $true
        # temporary not signing
        SignModule                        = $false
        DeleteTargetModuleBeforeBuild     = $true
        MergeModuleOnBuild                = $true
        CertificateThumbprint             = ''
        #CertificatePFXBase64           = $BasePfx
        #CertificatePFXPassword         = "zGT"
        DoNotAttemptToFixRelativePaths    = $false
        SkipBuiltinReplacements           = $true

        # required for Cmdlet/Alias functionality
        NETProjectPath                    = [io.path]::Combine($PSScriptRoot, '..', 'Sources', 'PSPublishModule')
        ResolveBinaryConflicts            = $true
        ResolveBinaryConflictsName        = 'PSPublishModule'
        NETProjectName                    = 'PSPublishModule'
        NETConfiguration                  = 'Release'
        NETFramework                      = 'net8.0', 'net472'
        NETHandleAssemblyWithSameName     = $true
        DotSourceLibraries                = $true
        DotSourceClasses                  = $true

        # This has to be disabled as it will not have DLLs required to do this
        NETBinaryModuleCmdletScanDisabled = $true
    }

    New-ConfigurationBuild @newConfigurationBuildSplat

    New-ConfigurationArtefact -Type Unpacked -Enable -Path ([io.path]::Combine($PSScriptRoot, '..', 'Artefacts', 'Unpacked', '<TagModuleVersionWithPreRelease>')) -RequiredModulesPath ([io.path]::Combine($PSScriptRoot, '..', 'Artefacts', 'Unpacked', '<TagModuleVersionWithPreRelease>', 'Modules')) -AddRequiredModules -CopyFiles @{
        "Examples/Step01.CreateModuleProject.ps1" = "Examples/Step01.CreateModuleProject.ps1"
        "Examples/Step02.BuildModuleOver.ps1"     = "Examples/Step02.BuildModuleOver.ps1"
    } -CopyFilesRelative

    New-ConfigurationArtefact -Type Packed -Enable -Path ([io.path]::Combine($PSScriptRoot, '..', 'Artefacts', 'PackedWithModules')) -IncludeTagName -ID 'ToGitHub' -AddRequiredModules -CopyFiles @{
        "Examples/Step01.CreateModuleProject.ps1" = "Examples/Step01.CreateModuleProject.ps1"
        "Examples/Step02.BuildModuleOver.ps1"     = "Examples/Step02.BuildModuleOver.ps1"
    } -CopyFilesRelative -ArtefactName "PSPublishModule.<TagModuleVersionWithPreRelease>-FullPackage.zip"

    New-ConfigurationArtefact -Type Packed -Enable -Path ([io.path]::Combine($PSScriptRoot, '..', 'Artefacts', 'Packed')) -IncludeTagName -ID 'ToGitHub' -ArtefactName "PSPublishModule.<TagModuleVersionWithPreRelease>.zip"

    New-ConfigurationTest -TestsPath ([io.path]::Combine($PSScriptRoot, '..', 'Tests')) -Enable

    # global options for publishing to github/psgallery
    # you can use FilePath where APIKey are saved in clear text or use APIKey directly
    #New-ConfigurationPublish -Type PowerShellGallery -FilePath 'C:\Support\Important\PowerShellGalleryAPI.txt' -Enabled:$true
    #New-ConfigurationPublish -Type GitHub -FilePath 'C:\Support\Important\GitHubAPI.txt' -UserName 'EvotecIT' -Enabled:$true -ID 'ToGitHub' -OverwriteTagName '<TagModuleVersionWithPreRelease>'
} -ExitCode