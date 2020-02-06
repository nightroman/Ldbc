
Import-Module Ldbc

# https://github.com/mbdavid/LiteDB/issues/1445
task TODO_FilterWithParameters {
	Use-LiteDatabase :memory: {
		# add document
		Add-LiteData test @{_id = 1; p1 = 1}

		# remove using filter with argument
		$r = Remove-LiteData test '$._id = @0' 1 -Result
		equals $r 0

		# remove using filter with parameter
		$r = Remove-LiteData test '$._id = @id' @{id = 1} -Result
		equals $r 0

		# remove using hardcoded filter
		$r = Remove-LiteData test '$._id = 1' -Result
		equals $r 1
	}
}

task TODO_DELETE_WithParameters {
	Use-LiteDatabase :memory: {
		# add document
		Add-LiteData test @{_id = 1; p1 = 1}

		$r = Invoke-LiteCommand 'DELETE test WHERE $._id = @0' 1
		equals $r 0

		$r = Invoke-LiteCommand 'DELETE test WHERE $._id = 1' 1
		equals $r 1
	}
}
