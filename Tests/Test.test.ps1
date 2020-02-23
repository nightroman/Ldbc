
Import-Module Ldbc

task Where {
	Use-LiteDatabase -Script {
		$test = Get-LiteCollection Test

		@{_id = 2; name = 'John'}, @{_id = 1; name = 'Mary'} | Add-LiteData $test

		$r = Test-LiteData $test 'name = "Mary"'
		equals $r $true

		$r = Test-LiteData $test 'name = @0', John
		equals $r $true

		$r = Test-LiteData $test 'name = @name', @{name = 'John'}
		equals $r $true

		$r = Test-LiteData $test 'name = "Mary2"'
		equals $r $false

		$r = Test-LiteData $test 'name = @0', John2
		equals $r $false

		$r = Test-LiteData $test 'name = @name', @{name = 'John2'}
		equals $r $false
	}
}

task ById {
	Use-LiteDatabase -Script {
		$test = Get-LiteCollection Test

		Add-LiteData $test @{_id = 28}

		$r = Test-LiteData $test -ById 28
		equals $r $true

		$r = Test-LiteData $test -ById 1
		equals $r $false
	}
}
