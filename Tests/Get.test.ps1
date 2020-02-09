
Import-Module Ldbc

task CountAndExists {
	Use-LiteDatabase :memory: {
		$test = Get-LiteCollection Test Int32

		# add data for tests
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
