
Import-Module Ldbc

# https://github.com/mbdavid/LiteDB/issues/1445
task TODO_FilterWithParameters {
	Use-LiteDatabase :memory: {
		$test = Get-LiteCollection Test

		# add document
		Add-LiteData $test @{_id = 1; p1 = 1}

		# remove using filter with argument
		$r = Remove-LiteData $test '$._id = @0' 1 -Result
		if (1 -eq $r) {
			Write-Warning TODO_FilterWithParameters-1
			return
		}
		equals $r 0 #! current wrong but known case

		# remove using filter with parameter
		$r = Remove-LiteData $test '$._id = @id' @{id = 1} -Result
		if (1 -eq $r) {
			Write-Warning TODO_FilterWithParameters-2
			return
		}
		equals $r 0 #! current wrong but known case

		# remove using hardcoded filter
		$r = Remove-LiteData $test '$._id = 1' -Result
		equals $r 1
	}
}

task TODO_DELETE_WithParameters {
	Use-LiteDatabase :memory: {
		$test = Get-LiteCollection Test Int32

		# add document
		Add-LiteData $test @{_id = 1; p1 = 1}

		$r = Invoke-LiteCommand 'DELETE test WHERE $._id = @0' 1
		if (1 -eq $r) {
			Write-Warning TODO_DELETE_WithParameters-1
			return
		}

		$r = Invoke-LiteCommand 'DELETE test WHERE $._id = 1' 1
		equals $r 1
	}
}
