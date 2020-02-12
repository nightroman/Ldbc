
. ./Zoo.ps1

task AsPSCustomObject {
	Use-LiteDatabase :memory: {
		$test = Get-LiteCollection Test Int32
		Add-LiteData $test (New-BsonBag)
		$r = Get-LiteData $test -As ps
		equals $r.GetType().Name PSCustomObject
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
