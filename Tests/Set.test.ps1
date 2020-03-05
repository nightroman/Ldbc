
Import-Module Ldbc

task Basic {
	Use-LiteDatabase :memory: {
		$test = Get-LiteCollection Test

		# `Upsert` 2 missing
		$data = @{_id = 1; v = 1}, @{_id = 2; v = 1}
		$r = $data | Set-LiteData $test -Add -Result
		# 2 added
		equals $r 2

		# `Upsert` 2 existing
		$data = @{_id = 1; v = 2}, @{_id = 2; v = 2}
		$r = $data | Set-LiteData $test -Add -Result
		# 0 added
		equals $r 0
		# but 2 updated
		$r = Get-LiteData $test
		equals "$r" '{"_id":1,"v":2} {"_id":2,"v":2}'

		# `Update` 1 missing (#1451 is not an issue in existing collection)
		$r = Set-LiteData $test @{_id = -1; v = 1} -Result
		equals $r 0
	}
}

task Bulk {
	Use-LiteDatabase :memory: {
		$test = Get-LiteCollection Test

		# add bulk (use duplicated key)
		$r = @{_id=1}, @{_id=1; p=1}, @{_id=2; p=2} | Set-LiteData $test -Add -Bulk -Result
		equals $r 2

		# set bulk (use missing key)
		$r = @{_id=1; p=2}, @{_id=2; p=3}, @{_id=3; p=4} | Set-LiteData $test -Bulk -Result
		equals $r 2

		$r = Get-LiteData $test
		equals "$r" '{"_id":1,"p":2} {"_id":2,"p":3}'
	}
}

# https://github.com/mbdavid/LiteDB/issues/1451
task UpdateInMissingCollection {
	Use-LiteDatabase :memory: {
		$test = Get-LiteCollection Test
		$r = Set-LiteData $test @{_id = 1; v = 1} -Result
		equals $r 0
	}
}

#! https://github.com/mbdavid/LiteDB/issues/1483
# .Upsert has issue.
task UpsertId0 {
	Use-LiteDatabase :memory: {
		$test = Get-LiteCollection Test Int32
		$d = [LiteDB.BsonDocument]::new()
		$d["_id"] = 0
		$r = $test.Upsert($d)
		equals $r $true
		$r = Get-LiteData $test
		equals "$r" '{"_id":0}'
	}
}

#_200223_064239, more comprehensive test is in Add
task DefaultId {
	Use-LiteDatabase :memory: {
		$test = Get-LiteCollection Test Int32

		Set-LiteData $test -Add @{_id = $null}
		Set-LiteData $test -Add @{_id = 0}
		Set-LiteData $test -Add @{_id = [LiteDB.ObjectId]::Empty}
		Set-LiteData $test -Add @{_id = [guid]::Empty}
		Set-LiteData $test -Add @{_id = 0L}

		$r = Get-LiteData $test
		equals "$r" '{"_id":{"$numberLong":"0"}} {"_id":1} {"_id":2} {"_id":{"$oid":"000000000000000000000000"}} {"_id":{"$guid":"00000000-0000-0000-0000-000000000000"}}'
	}
}
