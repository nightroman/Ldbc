
Import-Module Ldbc

task Basic {
	Use-LiteDatabase :memory: {
		$test = Get-LiteCollection Test

		# add documents
		@{_id = 1; p1 = 1}, @{_id = 2; p1 = 2}, @{_id = 3; p1 = 3} |
		Add-LiteData $test

		# query gets none -> updated 0
		$r = Update-LiteData $test ('$._id = @_id', @{_id = 99}) '{p1 : 99}' -Result
		equals $r 0

		# query gets some -> updated 1
		$r = Update-LiteData $test ('$._id = @_id', @{_id = 1}) ('{p1 : @p1}', @{p1 = -1}) -Result
		equals $r 1

		# query gets all -> updated all
		$r = Update-LiteData $test '$._id > 0' '{p1 : $.p1 + 1}' -Result
		equals $r 3

		$r = Get-LiteData $test
		equals "$r" '{"_id":1,"p1":0} {"_id":2,"p1":3} {"_id":3,"p1":4}'
	}
}

task AppendToArray {
	$database = New-LiteDatabase
	$test = Get-LiteCollection Test
	Add-LiteData $test @{_id = 1; p1 = @()}

	# append value
	Update-LiteData $test '$._id = 1' ('{p1: UNION($.p1, @v)}', @{v = 1})
	$r = Get-LiteData $test
	equals "$r" '{"_id":1,"p1":[1]}'

	# append array
	Update-LiteData $test '$._id = 1' ('{p1: UNION($.p1, @v)}', @{v = 2, 3})
	$r = Get-LiteData $test
	equals "$r" '{"_id":1,"p1":[1,2,3]}'

	$database.Dispose()
}
