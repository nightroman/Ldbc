
Import-Module Ldbc

task Constructors {
	# string
	$r = [Ldbc.Expression]::new('$.x = 1')
	equals "$r" '`$.x=1` [Equal]'

	# BsonExpression
	$e = [LiteDB.BsonExpression]::Create('$.x = 2')
	$r = [Ldbc.Expression]::new($e)
	equals "$r" '`$.x=2` [Equal]'

	# string, IDictionary
	$r = [Ldbc.Expression]::new('$.x = @x and $.y = @y', [ordered]@{x = 1; y = 2})
	$p = $r.Parameters
	equals "$r" '`$.x=@x AND $.y=@y` [And]'
	equals "$p" '{"x":1,"y":2}'

	# string, args
	$r = [Ldbc.Expression]::new('$.x = @0', 1)
	$p = $r.Parameters
	equals "$r" '`$.x=@0` [Equal]'
	equals "$p" '{"0":1}'
}
