
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

task GetCollectionDoesNotCreate {
	$database = New-LiteDatabase

	$test = Get-LiteCollection test
	$r = @($database.GetCollectionNames())
	equals $r.Count 0

	Get-LiteData $test
	$r = @($database.GetCollectionNames())
	equals $r.Count 0

	Add-LiteData $test @{p1 = 1}
	$r = @($database.GetCollectionNames())
	equals $r.Count 1

	$database.Dispose()
}

# Synopsis: Transactions are automatically committed on success.
# Also: Use-* cmdlets outputs data from invoked script blocks.
task AutoCommit {
	$stream = [System.IO.MemoryStream]::new()

	$r = Use-LiteDatabase $stream -Transaction {
		Invoke-LiteCommand 'INSERT INTO test : INT VALUES {p1 : 1}'
	}
	equals $r 1

	$r = Use-LiteDatabase $stream {
		Invoke-LiteCommand 'SELECT $ FROM test'
	}
	equals "$r" '{"_id":1,"p1":1}'
}

# Synopsis: Transactions are automatically rolled back on failures.
# Also: Error messages contain information about actual locations.
task AutoRollback {
	$stream = [System.IO.MemoryStream]::new()

	try {
		Use-LiteDatabase $stream -Transaction {
			$r = Invoke-LiteCommand 'INSERT INTO test : INT VALUES {p1 : 1}'
			equals $r 1

			$r = Invoke-LiteCommand 'SELECT $ FROM test'
			equals "$r" '{"_id":1,"p1":1}'

			throw 'oops'
		}
		throw
	}
	catch {
		"$_"
		assert ("$_" -like "oops*At*Database.test.ps1*throw 'oops'*")
	}

	Use-LiteDatabase $stream {
		$r = Invoke-LiteCommand 'SELECT $ FROM test'
		equals $r $null
	}
}
