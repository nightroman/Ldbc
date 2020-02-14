
. ./Zoo.ps1

task AsPS {
	Use-LiteDatabase :memory: {
		$test = Get-LiteCollection Test Int32
		Add-LiteData $test (New-BsonBag)
		$r = Get-LiteData $test -As PS
		equals $r.GetType().Name PSCustomObject
		equals $r.double 3.14
		equals $r.string bar
		equals $r.object.bar 1
		equals $r.array[0] 1
		equals $r.array[1] 2
		equals $r.binData04 ([guid]"cdccdb76-30a3-4d7c-97fa-5ae1ad28fd64")
		equals $r.binData00.GetType() ([byte[]])
		equals $r.objectId ([LiteDB.ObjectId]"5dc4c9808c94b4316c418f95")
		equals $r.bool $true
		equals $r.date ([DateTime]"2019-11-11")
		equals $r.null $null
		equals $r.int 42
		equals $r.long 42L
		equals $r.decimal 123456789.123456789d
		equals $r.minKey ([LiteDB.BsonValue]::MinValue)
		equals $r.maxKey ([LiteDB.BsonValue]::MaxValue)
	}
}

task AsType {
	# id ~ _id
	class T1 {$id; $p1}

	# literal mapping
	class T2 {$_id; $p1}

	# <ClassName>Id ~ _id
	class T3 {$T3Id; $p1}

	# no ID
	class T4 {$p1; $extra}

	Use-LiteDatabase :memory: {
		$test = Get-LiteCollection test

		Add-LiteData $test @{_id = 33; p1 = 38; extra = 60}

		$r = Get-LiteData $test -As T1
		equals $r.GetType() ([T1])
		equals $r.id 33
		equals $r.p1 38

		$r = Get-LiteData $test -As T2
		equals $r.GetType() ([T2])
		equals $r._id 33
		equals $r.p1 38

		$r = Get-LiteData $test -As T3
		equals $r.GetType() ([T3])
		equals $r.T3Id 33
		equals $r.p1 38

		$r = Get-LiteData $test -As T4
		equals $r.GetType() ([T4])
		equals $r.p1 38
		equals $r.extra 60

		$r = Get-LiteData $test -As ([System.Collections.Generic.Dictionary[string, object]])
		equals $r.GetType() ([System.Collections.Generic.Dictionary[string, object]])
		equals $r.Count 3
		equals $r._id 33

		# https://github.com/mbdavid/LiteDB/pull/1480
		$r = Get-LiteData $test -As ([object])
		equals $r.GetType() ([System.Collections.Generic.Dictionary[string, object]])
		equals $r.Count 0

		# https://github.com/mbdavid/LiteDB/pull/1480
		$r = Get-LiteData $test -As ([hashtable])
		equals $r.GetType() ([hashtable])
		equals $r.Count 0
	}
}

task CountAndExists {
	Use-LiteDatabase :memory: {
		$test = Get-LiteCollection Test Int32

		# add data
		@{name = 'John'; age = 42}, @{name = 'Mary'; age = 33} | Add-LiteData $test

		# test Test-LiteData
		equals (Test-LiteData $test '$.name = "Joe"') $false
		equals (Test-LiteData $test '$.name = "John"') $true
		equals (Test-LiteData $test '$.age > 20') $true
		equals (Test-LiteData $test '$.age > 50') $false

		# test Get-LiteData -Count
		equals (Get-LiteData -Count $test '$.name = "Joe"') 0
		equals (Get-LiteData -Count $test '$.name = "John"') 1
		equals (Get-LiteData -Count $test '$.age > 20') 2
		equals (Get-LiteData -Count $test '$.age > 40') 1
		equals (Get-LiteData -Count $test '$.age > 50') 0
	}
}

task FirstLastSkip {
	Use-LiteDatabase :memory: {
		$test = Get-LiteCollection Test

		# add data
		1..9 | .{process{ @{_id = $_} }} | Add-LiteData $test

		# get all

		$r = Get-LiteData $test -First 2
		equals "$r" '{"_id":1} {"_id":2}'

		$r = Get-LiteData $test -Last 2
		equals "$r" '{"_id":8} {"_id":9}'

		$r = Get-LiteData $test -Skip 2 -First 2
		equals "$r" '{"_id":3} {"_id":4}'

		$r = Get-LiteData $test -Skip 2 -Last 2
		equals "$r" '{"_id":6} {"_id":7}'

		# get where

		$filter = '$._id >= 3 AND $._id <= 7'

		$r = Get-LiteData $test $filter -First 2
		equals "$r" '{"_id":3} {"_id":4}'

		$r = Get-LiteData $test $filter -Last 2
		equals "$r" '{"_id":6} {"_id":7}'

		$r = Get-LiteData $test $filter -Skip 2 -First 2
		equals "$r" '{"_id":5} {"_id":6}'

		$r = Get-LiteData $test $filter -Skip 2 -Last 2
		equals "$r" '{"_id":4} {"_id":5}'
	}
}

task Select {
	Use-LiteDatabase :memory: {
		$test = Get-LiteCollection Test

		Add-LiteData $test @{p1 = 1; p2 = 2; p3 = 3}

		$r = Get-LiteData $test -Select '{s1:p3, s2:p1}'
		equals "$r" '{"s1":3,"s2":1}'
	}
}

task OrderBy {
	Use-LiteDatabase :memory: {
		$test = Get-LiteCollection Test Int32

		@{p=1}, @{p=3}, @{p=2} | Add-LiteData $test

		$r = Get-LiteData $test -Select p -OrderBy p
		equals "$r" '{"p":1} {"p":2} {"p":3}'

		$r = Get-LiteData $test -Select p -OrderBy p -Order -1
		equals "$r" '{"p":3} {"p":2} {"p":1}'
	}
}
