
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
	$d.emptyArray = @()
	$d.emptyDocument = @{}

	# ToString() ~> compact JSON
	$json1 = "$d"
	$json2 = $d.ToString()
	equals $json1 $json2
	$json1
	equals (Get-MD5 $json1) ([guid]'4863683c-996e-d132-cb17-9e6a0a25d089')

	# parse compact JSON
	$r = [Ldbc.Dictionary]::FromJson($json1)
	equals $r $d

	# Print() ~> pretty JSON
	$json3 = $d.Print()
	$json3
	equals (Get-MD5 $json3) ([guid]'9c4b58fc-dc2e-dc7a-40b2-016e15fc0a14')

	# parse pretty JSON
	$r = [Ldbc.Dictionary]::FromJson($json3)
	equals $r $d
}
