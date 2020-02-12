
Import-Module Ldbc

task Basic {
	Use-LiteDatabase :memory: {
		# INSERT
		$r = Invoke-LiteCommand 'INSERT INTO test : INT VALUES { p1 : 1 }, { p1 : "2" }, { p1 : 3.0 }'
		equals $r 3
		$r = Invoke-LiteCommand 'SELECT $ FROM test'
		equals "$r" '{"_id":1,"p1":1} {"_id":2,"p1":"2"} {"_id":3,"p1":3.0}'

		# DELETE with one argument
		$r = Invoke-LiteCommand 'DELETE test WHERE $._id > @0' 1
		equals $r 2
		$r = Invoke-LiteCommand 'SELECT $ FROM test'
		equals "$r" '{"_id":1,"p1":1}'

		# UPDATE with many arguments
		$r = Invoke-LiteCommand 'UPDATE test SET p1 = @1, p2 = @2 WHERE $._id = @0' 1, 2, 2
		equals $r 1
		$r = Invoke-LiteCommand 'SELECT $ FROM test'
		equals "$r" '{"_id":1,"p1":2,"p2":2}'

		# UPDATE with named parameters
		$r = Invoke-LiteCommand 'UPDATE test SET p1 = @p1, p2 = @p2 WHERE $._id = @id' @{id = 1; p1 = 3; p2 = 3}
		equals $r 1
		$r = Invoke-LiteCommand 'SELECT $ FROM test'
		equals "$r" '{"_id":1,"p1":3,"p2":3}'
	}
}

task As {
	Use-LiteDatabase :memory: {
		# INSERT
		Invoke-LiteCommand 'INSERT INTO test VALUES {_id: 1, p: 1}' -Quiet

		# SELECT with -As
		$r = Invoke-LiteCommand 'SELECT $ FROM test' -As PS
		$r | Out-String
		equals $r.GetType().Name PSCustomObject
	}
}

task Collection {
	Use-LiteDatabase :memory: {
		# way 1
		$name1 = ''
		$r = Invoke-LiteCommand 'SELECT $ FROM MyCollection' -Collection ([ref]$name1)
		equals $r $null
		equals $name1 MyCollection

		# way 2
		$name2 = [ref]''
		$r = Invoke-LiteCommand 'SELECT $ FROM MyCollection' -Collection $name2
		equals $r $null
		equals $name2.Value MyCollection
	}
}

task CannotInsertWithParameter1 {
	try {
		Use-LiteDatabase :memory: {
			Invoke-LiteCommand 'INSERT INTO test : INT VALUES @0' @(@{p1 = 1})
			throw
		}
	}
	catch {
		"$_"
		assert ("$_" -match '^Unexpected token `@` in position \d+')
	}
}

task CannotInsertWithParameter2 {
	try {
		Use-LiteDatabase :memory: {
			Invoke-LiteCommand 'INSERT INTO test : INT VALUES {p1 : @0}' 1
			throw
		}
	}
	catch {
		"$_"
		assert ("$_" -match '^Unexpected token `@` in position \d+')
	}
}
