
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

task ToBsonDocument {
	$d = [Ldbc.Dictionary]::new()
	$d._id = 1

	# explicit method
	$b = $d.ToBsonDocument()
	assert ([object]::ReferenceEquals($b, $d.ToBsonDocument()))

	# implicit operator
	$b = [LiteDB.BsonDocument]$d
	assert ([object]::ReferenceEquals($b, $d.ToBsonDocument()))
}

task ToBsonArray {
	$d = [Ldbc.Collection]::new()
	equals $d.Add(1) $null
	equals @($d.Add(1)).Count 0

	# explicit method
	$b = $d.ToBsonArray()
	assert ([object]::ReferenceEquals($b, $d.ToBsonArray()))

	# implicit operator
	$b = [LiteDB.BsonArray]$d
	assert ([object]::ReferenceEquals($b, $d.ToBsonArray()))
}

task Constructor {
	# from BsonDocument, wrap
	$b1 = [LiteDB.BsonDocument]::new()
	$d1 = [Ldbc.Dictionary]::new($b1)
	assert ([object]::ReferenceEquals($d1.ToBsonDocument(), $b1))

	# from Hashtable, convert
	$d1 = [Ldbc.Dictionary]::new(@{p1 = 1; a1 = @(1,2)})
	equals $d1.p1 1

	# from another Dictionary, deep clone
	$d2 = [Ldbc.Dictionary]::new($d1)
	equals $d2.p1 1
	assert (![object]::ReferenceEquals($d1.ToBsonDocument(), $d2.ToBsonDocument()))
	assert (![object]::ReferenceEquals($d1.a1.ToBsonArray(), $d2.a1.ToBsonArray()))

	# cast, not constructor!
	$d3 = [Ldbc.Dictionary]$d2
	assert ([object]::ReferenceEquals($d2, $d3))

	# but this is constructor!
	$d4 = [Ldbc.Dictionary]$b1
	assert ([object]::ReferenceEquals($d4.ToBsonDocument(), $b1))
}
