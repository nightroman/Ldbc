
Import-Module Ldbc

# Save Version as string.
function Register-Version {
	Register-LiteType ([Version]) {
		$_.ToString()
	} {
		[version]$_
	}
}

# Save file or directory item as array:
# 0: $true/$false ~ file/directory
# 1: .FullName
function Register-FileSystemInfo {
	Register-LiteType ([System.IO.FileSystemInfo]) {
		$_ -is [System.IO.FileInfo]
		$_.FullName
	} {
		if ($_[0]) {
			[System.IO.FileInfo]$_[1]
		}
		else {
			[System.IO.DirectoryInfo]$_[1]
		}
	}
}

class Version1 {
	[int] $Id
	[Version] $Version
}

class FileSystemInfo1 {
	[int] $Id
	[System.IO.FileSystemInfo] $Item
}

task Version {
	Register-Version

	$data = [Version1]@{
		Id = 1
		Version = '1.1'
	}

	$Database = New-LiteDatabase
	$test = Get-LiteCollection Test
	$data | Add-LiteData $test

	$r = Get-LiteData $test -As Version1
	$r | Out-String
	equals $r.Version ([Version]'1.1')

	$r = Get-LiteData $test
	equals "$r" '{"_id":1,"Version":"1.1"}'

	$Database.Dispose()
}

task FileSystemInfo {
	Register-FileSystemInfo

	$data = $(
		[FileSystemInfo1]@{
			Id = 1
			Item = Get-Item $BuildRoot
		}
		[FileSystemInfo1]@{
			Id = 2
			Item = Get-Item $BuildFile
		}
	)

	$Database = New-LiteDatabase
	$test = Get-LiteCollection Test
	$data | Add-LiteData $test

	$r = Get-LiteData $test -As FileSystemInfo1
	$r | Out-String
	equals $r[0].Item.GetType().Name DirectoryInfo
	equals $r[0].Item.FullName $BuildRoot
	equals $r[1].Item.GetType().Name FileInfo
	equals $r[1].Item.FullName $BuildFile

	$r1, $r2 = Get-LiteData $test
	equals "$r1" ('{"_id":1,"Item":[false,"' + $BuildRoot.Replace('\', '\\') + '"]}')
	equals "$r2" ('{"_id":2,"Item":[true,"' + $BuildFile.Replace('\', '\\') + '"]}')

	$Database.Dispose()
}
