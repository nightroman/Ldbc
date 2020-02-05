
Import-Module Ldbc

task NewDefault {
	$db = New-LiteDatabase
	equals $db.GetType() ([LiteDB.LiteDatabase])
	$db.Dispose()
}

task NewMemory {
	$db = New-LiteDatabase :memory:
	equals $db.GetType() ([LiteDB.LiteDatabase])
	$db.Dispose()
}

task NewStream {
	$stream = [System.IO.MemoryStream]::new()

	$db = New-LiteDatabase $stream
	equals $db.GetType() ([LiteDB.LiteDatabase])
	equals $db.UserVersion 0
	$db.UserVersion = 26
	$db.Dispose()

	equals $stream.ToArray().Length 8192

	$db = New-LiteDatabase $stream
	equals $db.GetType() ([LiteDB.LiteDatabase])
	equals $db.UserVersion 26
	$db.Dispose()
}

task UseFile {
	$file = "$BuildRoot\z.LiteDB"
	remove $file

	Use-LiteDatabase $file {
		equals $Database.GetType() ([LiteDB.LiteDatabase])
		equals $Database.UserVersion 0
		$Database.UserVersion = 26
	}

	assert (Test-Path $file)

	Use-LiteDatabase $file {
		equals $Database.GetType() ([LiteDB.LiteDatabase])
		equals $Database.UserVersion 26
	}

	remove $file
}

task UseStream {
	$stream = [System.IO.MemoryStream]::new()

	Use-LiteDatabase $stream {
		equals $Database.GetType() ([LiteDB.LiteDatabase])
		equals $Database.UserVersion 0
		$Database.UserVersion = 26
	}

	equals $stream.ToArray().Length 8192

	Use-LiteDatabase $stream {
		equals $Database.GetType() ([LiteDB.LiteDatabase])
		equals $Database.UserVersion 26
	}
}
