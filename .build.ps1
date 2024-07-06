<#
.Synopsis
	Build script, https://github.com/nightroman/Invoke-Build
#>

param(
	[string]$Configuration = 'Release'
	,
	[string]$TargetFramework = 'netstandard2.0'
)

Set-StrictMode -Version 3
$ModuleName = 'Ldbc'
$ModuleRoot = "$env:ProgramFiles\WindowsPowerShell\Modules\$ModuleName"

# Synopsis: Remove temp files.
task clean -After pushPSGallery {
	remove *.nupkg, z, Src\bin, Src\obj, README.htm
}

# Synopsis: Generate or update meta files.
task meta -Inputs .build.ps1, Release-Notes.md -Outputs "Module\$ModuleName.psd1", Src\Directory.Build.props -Jobs version, {
	$Project = 'https://github.com/nightroman/Ldbc'
	$Summary = 'LiteDB Cmdlets, the document store in PowerShell'
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

	PowerShellVersion = '5.1'
	GUID = '2838cc5c-7ecd-4f52-9aaf-dac1ec6b130e'

	PrivateData = @{
		PSData = @{
			Tags = 'LiteDB', 'Database', 'NoSQL', 'BSON', 'JSON'
			ProjectUri = '$Project'
			LicenseUri = 'http://www.apache.org/licenses/LICENSE-2.0'
			ReleaseNotes = '$Project/blob/main/Release-Notes.md'
		}
	}
}
"@

	Set-Content Src\Directory.Build.props @"
<Project>
	<PropertyGroup>
		<Company>$Project</Company>
		<Copyright>$Copyright</Copyright>
		<Description>$Summary</Description>
		<Product>$ModuleName</Product>
		<Version>$Version</Version>
		<IncludeSourceRevisionInInformationalVersion>False</IncludeSourceRevisionInInformationalVersion>
	</PropertyGroup>
</Project>
"@
}

# Synopsis: Build the project (and post-build Publish).
task build meta, {
	exec { dotnet build Src\$ModuleName.csproj -c $Configuration -f $TargetFramework }
}

# Synopsis: Publish the module (post-build).
task publish {
	remove $ModuleRoot
	exec { robocopy Module $ModuleRoot /s /np /r:0 /xf *-Help.ps1 } (0..3)
	exec { dotnet publish Src\$ModuleName.csproj -c $Configuration -f $TargetFramework --no-build }
	exec { robocopy Src\bin\$Configuration\$TargetFramework\publish $ModuleRoot /s /np /xf System.Management.Automation.dll } (0..3)
}

# Synopsis: Copy assembly comment docs to module.
task copyXml -After publish {
	$xml = [xml](Get-Content Src\$ModuleName.csproj)
	$node = $xml.SelectSingleNode('//PackageReference[@Include="LiteDB"]')
	if (!$node) {
		throw "Missing PackageReference LiteDB"
	}
	$dir = "$HOME\.nuget\packages\{0}\{1}\lib\netstandard2.0" -f $node.Include, $node.Version
	Copy-Item $dir\LiteDB.xml $ModuleRoot
}

# Synopsis: Build help by Helps (https://github.com/nightroman/Helps).
task help @{
	Inputs = {Get-Item Src\Commands\*, Module\en-US\$ModuleName.dll-Help.ps1}
	Outputs = {"$ModuleRoot\en-US\$ModuleName.dll-Help.xml"}
	Jobs = {
		. Helps.ps1
		Convert-Helps Module\en-US\$ModuleName.dll-Help.ps1 $Outputs
	}
}

# Synopsis: Make an test help.
task testHelp help, {
	. Helps.ps1
	Test-Helps Module\en-US\$ModuleName.dll-Help.ps1
}

# Synopsis: Convert markdown to HTML.
task markdown {
	assert (Test-Path $env:MarkdownCss)
	exec { pandoc.exe @(
		'README.md'
		'--output=README.htm'
		'--from=gfm'
		'--embed-resources'
		'--standalone'
		"--css=$env:MarkdownCss"
		"--metadata=pagetitle=$ModuleName"
	)}
}

# Synopsis: Set $script:Version.
task version {
	($script:Version = switch -Regex -File Release-Notes.md {'##\s+v(\d+\.\d+\.\d+)' {$Matches[1]; break}})
}

# Synopsis: Make the package.
task package build, help, testHelp, markdown, version, {
	assert ((Get-Module $ModuleName -ListAvailable).Version -eq ([Version]$Version))
	equals $Version (Get-Item $ModuleRoot\$ModuleName.dll).VersionInfo.ProductVersion

	remove z
	$null = mkdir z\$ModuleName

	Copy-Item -Recurse -Destination z\$ModuleName $(
		'LICENSE'
		'README.htm'
		"$ModuleRoot\*"
	)

	$result = Get-ChildItem z\$ModuleName -Recurse -File -Name | Out-String
	$sample = @'
Ldbc.deps.json
Ldbc.dll
Ldbc.pdb
Ldbc.psd1
LICENSE
LiteDB.dll
LiteDB.xml
README.htm
System.Buffers.dll
en-US\about_Ldbc.help.txt
en-US\Ldbc.dll-Help.xml
'@
	Assert-SameFile.ps1 -Text $sample $result $env:MERGE
}

# Synopsis: Make and push the PSGallery package.
task pushPSGallery package, {
	$NuGetApiKey = Read-Host NuGetApiKey
	Publish-Module -Path z\$ModuleName -NuGetApiKey $NuGetApiKey
}

# Synopsis: Test Desktop.
task desktop -After package {
	exec {powershell -NoProfile -Command Invoke-Build test}
}

# Synopsis: Test Core.
task core -After package {
	exec {pwsh -NoProfile -Command Invoke-Build test}
}

# Synopsis: Test current PowerShell.
task test {
	$ErrorView = 'NormalView'
	Invoke-Build ** Tests
}

# Synopsis: Make and clean.
task . build, help, clean
