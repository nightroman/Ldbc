
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

task Bulk {
	Use-LiteDatabase :memory: {
		$test = Get-LiteCollection Test

		try {
			# add bulk with duplicated keys
			@{_id=1}, @{_id=1} | Add-LiteData $test -Bulk
			throw
		}
		catch {
			equals "$_" "Cannot insert duplicate key in unique index '_id'. The duplicate value is '1'."
		}

		# bulk is undone
		equals $test.Count() 0

		# add normal bulk
		$r = @{_id=1}, @{_id=2} | Add-LiteData $test -Bulk -Result
		equals $r 2
		equals $test.Count() 2
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
task AddDefaultId {
	Use-LiteDatabase :memory: {
		$test = Get-LiteCollection Test Int32

		$(
			@{_id = $null}
			@{_id = 0}
			@{_id = [LiteDB.ObjectId]::Empty}
			@{_id = [guid]::Empty}
			@{_id = 0L}
		) | Add-LiteData $test

		$r = Get-LiteData $test
		equals "$r" '{"_id":1} {"_id":2} {"_id":3} {"_id":4} {"_id":5}'
	}
}
