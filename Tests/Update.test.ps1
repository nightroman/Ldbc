
Import-Module Ldbc

task Basic {
	Use-LiteDatabase :memory: {
		$test = Get-LiteCollection Test

		# add documents
		@{_id = 1; p1 = 1}, @{_id = 2; p1 = 2}, @{_id = 3; p1 = 3} |
		Add-LiteData $test

		# update 0
		$r = Update-LiteData $test '$._id = @_id', @{_id = 99} '{p1 : 99}' -Result
		equals $r 0

		# update 1
		$r = Update-LiteData $test '$._id = @_id', @{_id = 1} '{p1 : @p1}', @{p1 = -1} -Result
		equals $r 1

		# update many
		$r = Update-LiteData $test '$._id > 0' '{p1 : $.p1 + 1}' -Result
		equals $r 3

		$r = Get-LiteData $test
		equals "$r" '{"_id":1,"p1":0} {"_id":2,"p1":3} {"_id":3,"p1":4}'
	}
}
