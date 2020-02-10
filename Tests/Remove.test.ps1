
Import-Module Ldbc

# https://github.com/mbdavid/LiteDB/issues/1445
task FilterWithParameters {
	Use-LiteDatabase :memory: {
		$test = Get-LiteCollection Test

		# add data
		@{_id = 1}, @{_id = 2} | Add-LiteData $test

		# remove using filter with parameter
		$r = Remove-LiteData $test '$._id = @_id', @{_id = 1} -Result
		equals $r 1 #! was 0

		# remove using hardcoded filter
		$r = Remove-LiteData $test '$._id = 2' -Result
		equals $r 1

		equals $test.Count() 0
	}
}

# https://github.com/mbdavid/LiteDB/issues/1445
task DELETE_WithParameters {
	Use-LiteDatabase :memory: {
		$test = Get-LiteCollection Test Int32

		# add data
		@{_id = 1}, @{_id = 2}, @{_id = 3} | Add-LiteData $test

		# parameter dictionary
		$r = Invoke-LiteCommand 'DELETE test WHERE $._id = @_id' @{_id = 1}
		equals $r 1 #! was 0

		# parameter argument
		$r = Invoke-LiteCommand 'DELETE test WHERE $._id = @0' 2
		equals $r 1 #! was 0

		# hardcoded
		$r = Invoke-LiteCommand 'DELETE test WHERE $._id = 3'
		equals $r 1

		equals $test.Count() 0
	}
}
