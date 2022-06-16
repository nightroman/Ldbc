
Import-Module Ldbc

# Synopsis: Transactions are automatically committed on success.
# Also: Use-* cmdlets outputs data from invoked script blocks.
task AutoCommit {
	$stream = [System.IO.MemoryStream]::new()

	$r = Use-LiteDatabase -Stream $stream {
		Use-LiteTransaction {
			Invoke-LiteCommand 'INSERT INTO test : INT VALUES {p1 : 1}'
		}
	}
	equals $r 1

	$r = Use-LiteDatabase -Stream $stream {
		Invoke-LiteCommand 'SELECT $ FROM test'
	}
	equals "$r" '{"_id":1,"p1":1}'
}

# Synopsis: Transactions are automatically rolled back on failures.
# Also: Error messages contain information about actual locations.
task AutoRollback {
	$stream = [System.IO.MemoryStream]::new()

	try {
		Use-LiteDatabase -Stream $stream {
			Use-LiteTransaction {
				$r = Invoke-LiteCommand 'INSERT INTO test : INT VALUES {p1 : 1}'
				equals $r 1

				$r = Invoke-LiteCommand 'SELECT $ FROM test'
				equals "$r" '{"_id":1,"p1":1}'

				throw 'oops'
			}
		}
		throw
	}
	catch {
		"$_"
		assert ("$_" -like "oops*throw 'oops'*Use-LiteTransaction {*")
	}

	Use-LiteDatabase -Stream $stream {
		$r = Invoke-LiteCommand 'SELECT $ FROM test'
		equals $r $null
	}
}
