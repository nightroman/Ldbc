@{
	Author = 'Roman Kuzmin'
	ModuleVersion = '0.0.0'
	Description = 'LiteDB Cmdlets, the document store in PowerShell'
	CompanyName = 'https://github.com/nightroman'
	Copyright = 'Copyright (c) Roman Kuzmin'

	RootModule = 'Ldbc.dll'
	RequiredAssemblies = 'LiteDB.dll'

	PowerShellVersion = '7.4'
	GUID = '2838cc5c-7ecd-4f52-9aaf-dac1ec6b130e'

	AliasesToExport = @()
	VariablesToExport = @()
	FunctionsToExport = @()
	CmdletsToExport = @(
		'Add-LiteData'
		'Get-LiteCollection'
		'Get-LiteData'
		'Invoke-LiteCommand'
		'New-LiteDatabase'
		'Register-LiteType'
		'Remove-LiteData'
		'Set-LiteData'
		'Test-LiteData'
		'Update-LiteData'
		'Use-LiteDatabase'
		'Use-LiteTransaction'
	)

	PrivateData = @{
		PSData = @{
			Tags = 'LiteDB', 'Database', 'NoSQL', 'BSON', 'JSON'
			ProjectUri = 'https://github.com/nightroman/Ldbc'
			LicenseUri = 'http://www.apache.org/licenses/LICENSE-2.0'
			ReleaseNotes = 'https://github.com/nightroman/Ldbc/blob/main/Release-Notes.md'
		}
	}
}
