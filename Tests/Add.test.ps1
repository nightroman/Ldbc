
Import-Module Ldbc

task Result {
	Use-LiteDatabase :memory: {
		# no result
		$r = @(Add-LiteData test -AutoId Int32 @{p1 = 1})
		equals $r.Count 0

		# one result
		$r = Add-LiteData test -AutoId Int32 @{p1 = 2} -Result
		equals $r 2

		# many results
		$r = @{p1 = 3}, @{p1 = 4} | Add-LiteData test -AutoId Int32 -Result
		equals $r.Count 2
		equals $r[0] 3
		equals $r[1] 4

		# test
		$r = Get-LiteData test
		equals "$r" '{"_id":1,"p1":1} {"_id":2,"p1":2} {"_id":3,"p1":3} {"_id":4,"p1":4}'
	}
}
