﻿Describe 'Step-Version - Tests' {
    It 'Testing version 0.1.X' {
        $Features = Import-Module $PSScriptRoot\..\PSPublishModule.psd1 -PassThru
        $Output = & $Features {
            Step-Version -Module 'PowerShellManager' -ExpectedVersion '0.1.X'
        }
        $Output | Should -Be "0.1.3"
    }
    It "Testing version 0.2.X" {
        $Features = Import-Module $PSScriptRoot\..\PSPublishModule.psd1 -PassThru
        $Output = & $Features {
            Step-Version -Module 'PowerShellManager' -ExpectedVersion '0.2.X'
        }
        $Output | Should -Be "0.2.0"
    }
}