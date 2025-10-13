<#
.Synopsis
	Build script, https://github.com/nightroman/Invoke-Build
#>

param(
	$Configuration = 'Release'
)

Set-StrictMode -Version 3
$ModuleName = 'Ldbc'
$ModuleRoot = "$env:ProgramFiles\PowerShell\Modules\$ModuleName"

# Synopsis: Remove temp files.
task clean -After pushPSGallery {
	remove *.nupkg, z, Src\bin, Src\obj, README.html
}

# Synopsis: Generate meta files.
task meta -Inputs $BuildFile, Release-Notes.md -Outputs Src\Directory.Build.props -Jobs version, {
	Set-Content Src\Directory.Build.props @"
<Project>
	<PropertyGroup>
		<Company>https://github.com/nightroman/Ldbc</Company>
		<Copyright>Copyright (c) Roman Kuzmin</Copyright>
		<Description>LiteDB Cmdlets, the document store in PowerShell</Description>
		<Product>$ModuleName</Product>
		<Version>$Version</Version>
		<IncludeSourceRevisionInInformationalVersion>False</IncludeSourceRevisionInInformationalVersion>
	</PropertyGroup>
</Project>
"@
}

# Synopsis: Build, publish in post-build, make help.
task build meta, {
	exec { dotnet build "Src\$ModuleName.csproj" -c $Configuration --tl:off }
}

# Synopsis: Publish the module (post-build).
task publish {
	exec { dotnet publish "Src\$ModuleName.csproj" -c $Configuration -o $ModuleRoot --no-build }
	remove "$ModuleRoot\System.Management.Automation.dll", "$ModuleRoot\*.deps.json"
	Copy-Item Content\* $ModuleRoot
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

# Synopsis: Build help, https://github.com/nightroman/Helps
task help -After ?build -Inputs {Get-Item Src\Commands\*, Help.ps1} -Outputs "$ModuleRoot\$ModuleName.dll-Help.xml" {
	. Helps.ps1
	Convert-Helps Help.ps1 $Outputs
	Test-Helps Help.ps1
}

# Synopsis: Convert markdown to HTML.
task markdown {
	requires -Path $env:MarkdownCss
	exec { pandoc.exe @(
		'README.md'
		'--output=README.html'
		'--from=gfm'
		'--embed-resources'
		'--standalone'
		"--css=$env:MarkdownCss"
		"--metadata=pagetitle=$ModuleName"
	)}
}

# Synopsis: Set $Script:Version.
task version {
	($Script:Version = Get-BuildVersion Release-Notes.md '##\s+v(\d+\.\d+\.\d+)')
}

# Synopsis: Make the package.
task package markdown, version, {
	equals $Version (Get-Item "$ModuleRoot\$ModuleName.dll").VersionInfo.ProductVersion

	remove z
	$toModule = New-Item z\$ModuleName -ItemType Directory

	Copy-Item -Recurse -Destination $toModule $(
		'LICENSE'
		'README.html'
		"$ModuleRoot\*"
	)

	$text = [System.IO.File]::ReadAllText("$toModule\$ModuleName.psd1")
	[System.IO.File]::WriteAllText("$toModule\$ModuleName.psd1", $text.Replace('0.0.0', $Version))

	Assert-SameFile.ps1 -Result (Get-ChildItem $toModule -Recurse -File -Name) -Text -View $env:MERGE @'
about_Ldbc.help.txt
Ldbc.dll
Ldbc.dll-Help.xml
Ldbc.pdb
Ldbc.psd1
LICENSE
LiteDB.dll
LiteDB.xml
README.html
'@
}

# Synopsis: Make and push the PSGallery package.
task pushPSGallery package, {
	$NuGetApiKey = Read-Host NuGetApiKey
	Publish-Module -Path z\$ModuleName -NuGetApiKey $NuGetApiKey
}

# Synopsis: Run tests.
task test {
	$ErrorView = 'NormalView'
	Invoke-Build ** Tests
}

# Synopsis: Build and clean.
task . build, clean
