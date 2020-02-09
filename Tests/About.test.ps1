
Import-Module Ldbc

# README example
function DemoAddGetRemove {
	Use-LiteDatabase :memory: {
		# get the collection, specify auto id
		$test = Get-LiteCollection Test Int32

		# add two documents
		@{Name = 'John'}, @{Name = 'Mary'} | Add-LiteData $test

		# find using filter with parameters
		$r = Get-LiteData $test '$.Name = @Name', @{Name = 'John'}
		"$r" # {"_id":1,"Name":"John"}

		# remove one document
		Remove-LiteData $test '$._id = 1'

		# get all documents
		$r = Get-LiteData $test
		"$r" # {"_id":2,"Name":"Mary"}
	}
}

# README example
function DemoSqlCommands {
	Use-LiteDatabase :memory: {
		# add two documents
		Invoke-LiteCommand 'INSERT INTO Test : INT VALUES {Name: "John"}, {Name: "Mary"}' -Quiet

		# find using WHERE with parameters
		$r = Invoke-LiteCommand 'SELECT $ FROM Test WHERE $.Name = @param1' @{param1 = 'John'}
		"$r" # {"_id":1,"Name":"John"}

		# remove one document
		Invoke-LiteCommand 'DELETE Test WHERE $._id = 1' -Quiet

		# get all documents
		$r = Invoke-LiteCommand 'SELECT $ FROM Test'
		"$r" # {"_id":2,"Name":"Mary"}
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
