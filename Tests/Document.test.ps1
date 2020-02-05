
. ./Zoo.ps1

task DotNotation {
	# Ldbc dictionary (document wrapper) supports dot notation
	$d = [Ldbc.Dictionary]::new()
	$d._id = 1

	# native LiteDB document does not
	$d = [LiteDB.BsonDocument]::new()
	try {
		$d._id = 1
		throw
	}
	catch {
		equals $_.FullyQualifiedErrorId PropertyAssignmentException
	}
}

task Json {
	$d = New-BsonBag

	# ToString() ~> compact JSON
	$json1 = "$d"
	$json2 = $d.ToString()
	equals $json1 $json2
	$json1

	# parse compact JSON
	$r = [Ldbc.Dictionary]::FromJson($json1)
	equals $r $d

	# Print() ~> formatted JSON
	$json3 = $d.Print()
	$json3

	# parse formatted JSON
	$r = [Ldbc.Dictionary]::FromJson($json3)
	equals $r $d
}
