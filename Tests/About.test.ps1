
Import-Module Ldbc

# README example
function DemoAddGetRemove {
	Use-LiteDatabase :memory: {
		# get the collection, specify auto id
		$test = Get-LiteCollection Test Int32

		# add two documents
		$data = @{Name = 'John'}, @{Name = 'Mary'}
		$data | Add-LiteData $test

		# find using the filter with parameters
		# ~> {"_id":1,"Name":"John"}
		$r = Get-LiteData $test '$.Name = @param1' @{param1 = 'John'}
		"$r"

		# remove one document
		Remove-LiteData $test '$._id = 1'

		# get all remaining documents
		# ~> {"_id":2,"Name":"Mary"}
		$r = Get-LiteData $test
		"$r"
	}
}

# README example
function DemoSqlCommands {
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
}

# test example
task DemoAddGetRemove {
	$r = DemoAddGetRemove
	equals $r.Count 2
	equals $r[0] '{"_id":1,"Name":"John"}'
	equals $r[1] '{"_id":2,"Name":"Mary"}'
}

# test example
task DemoSqlCommands {
	$r = DemoSqlCommands
	equals $r.Count 2
	equals $r[0] '{"_id":1,"Name":"John"}'
	equals $r[1] '{"_id":2,"Name":"Mary"}'
}

# warm up and time examples
task MeasureDemo DemoAddGetRemove, DemoSqlCommands, {
	(Measure-Command { DemoAddGetRemove }).TotalMilliseconds
	(Measure-Command { DemoSqlCommands }).TotalMilliseconds
}
