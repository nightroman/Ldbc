
Import-Module Ldbc

task DemoAddGetRemove {
	$r =
	Use-LiteDatabase :memory: {
		# add two documents
		$data = @{Name = 'John'}, @{Name = 'Mary'}
		$data | Add-LiteData Test -AutoId Int32

		# find using the filter with parameters
		# ~> {"_id":1,"Name":"John"}
		$r = Get-LiteData Test '$.Name = @param1' @{param1 = 'John'}
		"$r"

		# remove one document
		Remove-LiteData Test '$._id = 1'

		# get all remaining documents
		# ~> {"_id":2,"Name":"Mary"}
		$r = Get-LiteData Test
		"$r"
	}
	equals $r.Count 2
	equals $r[0] '{"_id":1,"Name":"John"}'
	equals $r[1] '{"_id":2,"Name":"Mary"}'
}

task DemoCommands {
	$r =
	Use-LiteDatabase :memory: {
		# add two documents
		Invoke-LiteCommand 'INSERT INTO Test : INT VALUES {Name: "John"}, {Name: "Mary"}' -Quiet

		# find using the filter with parameters
		# ~> {"_id":1,"Name":"John"}
		$r = Invoke-LiteCommand 'SELECT $ FROM Test WHERE $.Name = @param1' @{param1 = 'John'}
		"$r"

		# remove one document
		Invoke-LiteCommand 'DELETE Test WHERE $._id = 1' -Quiet

		# get all remaining documents
		# ~> {"_id":2,"Name":"Mary"}
		$r = Invoke-LiteCommand 'SELECT $ FROM Test'
		"$r"
	}
	equals $r.Count 2
	equals $r[0] '{"_id":1,"Name":"John"}'
	equals $r[1] '{"_id":2,"Name":"Mary"}'
}
