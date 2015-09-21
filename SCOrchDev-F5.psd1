﻿#
# Module manifest for module 'SCOrchDev-F5'
#
# Generated by: Ryan Andorfer
#
# Generated on: 2015-02-27
#

@{

# Script module or binary module file associated with this manifest.
RootModule = '.\SCOrchDev-F5.psm1'

# Version number of this module.
ModuleVersion = '1.0.0'

# ID used to uniquely identify this module
GUID = 'd705ab9b-8b88-4642-9cb6-9a152f69f19f'

# Author of this module
Author = 'Ryan Andorfer'

# Company or vendor of this module
CompanyName = 'SCOrch Dev'

# Copyright statement for this module
Copyright = '(c) SCOrchDev. All rights reserved.'

# Description of the functionality provided by this module
Description = 'A wrapper around the F5 icontrol library'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '4.0'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @('SCOrchDev-Exception', 'SCOrchDev-Utility', 'SCOrchDev-Networking')

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module
FunctionsToExport = '*'

# Cmdlets to export from this module
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module
AliasesToExport = '*'

# List of all modules packaged with this module
ModuleList = @('SCOrchDev-F5')

# List of all files packaged with this module
FileList = @('SCOrchDev-F5.psd1', 'SCOrchDev-F5.psm1', 'LICENSE', 'README.md', 'SCOrchDev-F5.tests.ps1')

# Private data to pass to the module specified in RootModule/ModuleToProcess
# PrivateData = ''

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

