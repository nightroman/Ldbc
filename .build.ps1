<#
.Synopsis
	Build script (https://github.com/nightroman/Invoke-Build)
#>

param(
	$Configuration = 'Release',
	$TargetFramework = 'net45'
)

Set-StrictMode -Version 2
$ModuleName = 'Ldbc'
$ModuleRoot = if ($env:ProgramW6432) {$env:ProgramW6432} else {$env:ProgramFiles}
$ModuleRoot = "$ModuleRoot\WindowsPowerShell\Modules\$ModuleName"

# Get version from release notes.
function Get-Version {
	switch -Regex -File Release-Notes.md {'##\s+v(\d+\.\d+\.\d+)' {return $Matches[1]} }
}

$MetaParam = @{
	Inputs = '.build.ps1', 'Release-Notes.md'
	Outputs = "Module\$ModuleName.psd1", 'Src\AssemblyInfo.cs'
}

# Synopsis: Generate or update meta files.
task Meta @MetaParam {
	$Version = Get-Version
	$Project = 'https://github.com/nightroman/Ldbc'
	$Summary = 'Ldbc module - LiteDB Cmdlets for PowerShell'
	$Copyright = 'Copyright (c) Roman Kuzmin'

	Set-Content Module\$ModuleName.psd1 @"
@{
	Author = 'Roman Kuzmin'
	ModuleVersion = '$Version'
	Description = '$Summary'
	CompanyName = 'https://github.com/nightroman'
	Copyright = '$Copyright'

	RootModule = '$ModuleName.dll'
	RequiredAssemblies = 'LiteDB.dll'

	PowerShellVersion = '3.0'
	GUID = '2838cc5c-7ecd-4f52-9aaf-dac1ec6b130e'

	PrivateData = @{
		PSData = @{
			Tags = 'LiteDB', 'Database', 'NoSQL', 'BSON', 'JSON'
			ProjectUri = '$Project'
			LicenseUri = 'http://www.apache.org/licenses/LICENSE-2.0'
			ReleaseNotes = '$Project/blob/master/Release-Notes.md'
		}
	}
}
"@

	Set-Content Src\AssemblyInfo.cs @"
using System;
using System.Reflection;
using System.Runtime.InteropServices;

[assembly: AssemblyProduct("$ModuleName")]
[assembly: AssemblyVersion("$Version")]
[assembly: AssemblyTitle("$Summary")]
[assembly: AssemblyCompany("$Project")]
[assembly: AssemblyCopyright("$Copyright")]

[assembly: ComVisible(false)]
[assembly: CLSCompliant(false)]
"@
}

# Synopsis: Build the project (and post-build Publish).
task Build Meta, {
	exec { dotnet build Src\$ModuleName.csproj -c $Configuration -f $TargetFramework }
}

# Synopsis: Publish the module (post-build).
task Publish {
	remove $ModuleRoot
	exec { robocopy Module $ModuleRoot /s /np /r:0 /xf *-Help.ps1 } (0..3)
	exec { robocopy Src\bin\$Configuration\$TargetFramework $ModuleRoot /s /np /r:0 } (0..3)
},
CopyXml

task CopyXml {
	$xml = [xml](Get-Content Src\$ModuleName.csproj)
	$_ = $xml.SelectSingleNode('//PackageReference[@Include="LiteDB"]')
	if ($_) {
		$from = "$env:USERPROFILE\.nuget\packages\{0}\{1}\lib\net45" -f $_.Include, $_.Version
		Copy-Item $from\*.xml $ModuleRoot
	}
	else {
		# when reference LiteDB.csproj
		Write-Warning "Missing PackageReference LiteDB"
	}
}

# Synopsis: Remove temp files.
task Clean {
	remove *.nupkg, z, Src\bin, Src\obj, README.htm
}

# Synopsis: Build help by Helps (https://github.com/nightroman/Helps).
task Help @{
	Inputs = {Get-Item Src\Commands\*, Module\en-US\$ModuleName.dll-Help.ps1}
	Outputs = {"$ModuleRoot\en-US\$ModuleName.dll-Help.xml"}
	Jobs = {
		. Helps.ps1
		Convert-Helps Module\en-US\$ModuleName.dll-Help.ps1 $Outputs
	}
}

# Synopsis: Make an test help.
task TestHelp Help, {
	. Helps.ps1
	Test-Helps Module\en-US\$ModuleName.dll-Help.ps1
}

# Synopsis: Test in the current PowerShell.
task Test {
	$ErrorView = 'NormalView'
	Invoke-Build ** Tests
}

# Synopsis: Test in PowerShell v6.
task Test6 -If $env:powershell6 {
	exec {& $env:powershell6 -NoProfile -Command Invoke-Build Test}
}

# Synopsis: Convert markdown to HTML.
task Markdown {
	assert (Test-Path $env:MarkdownCss)
	exec { pandoc.exe @(
		'README.md'
		'--output=README.htm'
		'--from=gfm'
		'--self-contained', "--css=$env:MarkdownCss"
		'--standalone', "--metadata=pagetitle=$ModuleName"
	)}
}

# Synopsis: Set $script:Version.
task Version {
	($script:Version = Get-Version)
	# manifest version
	$data = & ([scriptblock]::Create([IO.File]::ReadAllText("$ModuleRoot\$ModuleName.psd1")))
	assert ($data.ModuleVersion -eq $script:Version)
	# assembly version
	assert ((Get-Item $ModuleRoot\$ModuleName.dll).VersionInfo.FileVersion -eq ([Version]"$script:Version.0"))
}

# Synopsis: Make the package in z\tools.
task Package Full, Markdown, {
	remove z
	$null = mkdir z\tools\$ModuleName

	Copy-Item -Recurse -Destination z\tools\$ModuleName $(
		'LICENSE.txt'
		'README.htm'
		"$ModuleRoot\*"
	)
}

# Synopsis: Make and push the PSGallery package.
task PushPSGallery Package, Version, {
	$NuGetApiKey = Read-Host NuGetApiKey
	Publish-Module -Path z/tools/$ModuleName -NuGetApiKey $NuGetApiKey
},
Clean

# Synopsis: Fast dev round.
task Fast Build, Help, Test, Clean

# Synopsis: Full dev round.
task Full Build, Help, TestHelp, Test, Test6, Clean

task . Fast
