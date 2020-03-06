
Import-Module Ldbc

task Result {
	Use-LiteDatabase :memory: {
		$test = Get-LiteCollection Test Int32

		# no result
		$r = @(Add-LiteData $test @{p1 = 1})
		equals $r.Count 0

		# one result
		$r = Add-LiteData $test @{p1 = 2} -Result
		equals $r 2

		# many results
		$r = @{p1 = 3}, @{p1 = 4} | Add-LiteData $test -Result
		equals $r.Count 2
		equals $r[0] 3
		equals $r[1] 4

		# test
		$r = Get-LiteData $test
		equals "$r" '{"_id":1,"p1":1} {"_id":2,"p1":2} {"_id":3,"p1":3} {"_id":4,"p1":4}'
	}
}

task AddWithError {
	Use-LiteDatabase :memory: {
		$test = Get-LiteCollection Test
		try {
			# add two with duplicated keys
			@{_id=1}, @{_id=1} | Add-LiteData $test
			throw
		}
		catch {
			equals "$_" "Cannot insert duplicate key in unique index '_id'. The duplicate value is '1'."
		}

		# one document is still added
		equals $test.Count() 1

		# add two with duplicated keys and one more, ignore errors
		$r1, $r2 = @{_id=2}, @{_id=2}, @{_id=3} | Add-LiteData $test -ErrorAction Ignore -Result
		equals $r1 2
		equals $r2 3
	}
}

#! https://github.com/mbdavid/LiteDB/issues/1483
# .Insert has issue.
task InsertId0 {
	Use-LiteDatabase :memory: {
		$test = Get-LiteCollection Test Int32
		$d = [LiteDB.BsonDocument]::new()
		$d["_id"] = 0
		$r = $test.Insert($d)
		equals $r.AsInt32 0
		$r = Get-LiteData $test
		equals "$r" '{"_id":0}'
	}
}

#_200223_064239
task DefaultId_Int32 {
	Use-LiteDatabase :memory: {
		$test = Get-LiteCollection Test Int32
		$(
			@{_id = $null; t = 'null'}
			@{_id = 0; t = 'int'}
			@{_id = [LiteDB.ObjectId]::Empty; t = 'oid'}
			@{_id = [guid]::Empty; t = 'guid'}
			@{_id = 0L; t = 'long' }
		) | Add-LiteData $test
		$r = Get-LiteData $test
		equals "$r" '{"_id":{"$numberLong":"0"},"t":"long"} {"_id":1,"t":"null"} {"_id":2,"t":"int"} {"_id":{"$oid":"000000000000000000000000"},"t":"oid"} {"_id":{"$guid":"00000000-0000-0000-0000-000000000000"},"t":"guid"}'
	}
}

#_200223_064239
task DefaultId_Int64 {
	Use-LiteDatabase :memory: {
		$test = Get-LiteCollection Test Int64
		$(
			@{_id = $null; t = 'null'}
			@{_id = 0; t = 'int'}
			@{_id = [LiteDB.ObjectId]::Empty; t = 'oid'}
			@{_id = [guid]::Empty; t = 'guid'}
			@{_id = 0L; t = 'long' }
		) | Add-LiteData $test
		$r = Get-LiteData $test
		equals "$r" '{"_id":0,"t":"int"} {"_id":{"$numberLong":"1"},"t":"null"} {"_id":{"$numberLong":"2"},"t":"long"} {"_id":{"$oid":"000000000000000000000000"},"t":"oid"} {"_id":{"$guid":"00000000-0000-0000-0000-000000000000"},"t":"guid"}'
	}
}

#_200223_064239
task DefaultId_Oid {
	Use-LiteDatabase :memory: {
		$test = Get-LiteCollection Test
		$(
			@{_id = $null; t = 'null'}
			@{_id = 0; t = 'int'}
			@{_id = [LiteDB.ObjectId]::Empty; t = 'oid'}
			@{_id = [guid]::Empty; t = 'guid'}
			#! cannot, duplicate key 0: @{_id = 0L; t = 'long' }
		) | Add-LiteData $test
		$r = Get-LiteData $test
		Write-Host "$r"
		assert ("$r" -match '^{"_id":0,"t":"int"} {"_id":{"\$oid":"\w+"},"t":"null"} {"_id":{"\$oid":"\w+"},"t":"oid"} {"_id":{"\$guid":"00000000-0000-0000-0000-000000000000"},"t":"guid"}')
	}
}

#_200223_064239
task DefaultId_Guid {
	Use-LiteDatabase :memory: {
		$test = Get-LiteCollection Test Guid
		$(
			@{_id = $null; t = 'null'}
			@{_id = 0; t = 'int'}
			@{_id = [LiteDB.ObjectId]::Empty; t = 'oid'}
			@{_id = [guid]::Empty; t = 'guid'}
			#! cannot, duplicate key 0: @{_id = 0L; t = 'long' }
		) | Add-LiteData $test
		$r = Get-LiteData $test
		Write-Host "$r"
		assert ("$r" -match '^{"_id":0,"t":"int"} {"_id":{"\$oid":"000000000000000000000000"},"t":"oid"} {"_id":{"\$guid":".{36}"},"t":".{4}"} {"_id":{"\$guid":".{36}"},"t":".{4}"}')
	}
}
