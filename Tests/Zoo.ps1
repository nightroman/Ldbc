<#
.Synopsis
	Common test tools.
#>

Import-Module Ldbc

$IsUnix = $PSVersionTable['Platform'] -eq 'Unix'

# Gets a dictionary with all known bson types
function New-BsonBag {
	$m = [Ldbc.Dictionary]::new()
	# 1 Double - round trip [double]
	$m.double = 3.14
	# 2 String - round trip [string]
	$m.string = 'bar'
	# 3 Object - object/dictionary -> BsonDocument -> Ldbc.Dictionary
	$m.object = @{bar = 1}
	# 4 Array - collection -> BsonArray -> Ldbc.Collection
	$m.array = @(1, 2)
	# 5 Binary - round trip [guid], one way [byte[]]
	# guid - round trip [guid]
	$m.binData04 = [guid]"cdccdb76-30a3-4d7c-97fa-5ae1ad28fd64"
	# bytes - one way byte[] -> BsonBinaryData
	$m.binData00 = [byte[]](1, 2)
	# 7 ObjectId - round trip [MongoDB.Bson.ObjectId]
	$m.objectId = [LiteDB.ObjectId]"5dc4c9808c94b4316c418f95"
	# 8 Boolean - round trip [bool]
	$m.bool = $true
	# 9 Date - round trip [DateTime]
	$m.date = [DateTime]"2019-11-11"
	# 10 Null - round trip $null
	$m.null = $null
	# 16 Int32 - round trip [int]
	$m.int = 42
	# 18 Int64 - round trip [long]
	$m.long = 42L
	# 19 Decimal128 -- round trip [decimal]
	$m.decimal = 123456789.123456789d
	# -1 MinKey - singleton [MongoDB.Bson.BsonMinKey]
	$m.minKey = [LiteDB.BsonValue]::MinValue
	# 127 MaxKey - singleton [MongoDB.Bson.BsonMaxKey]
	$m.maxKey = [LiteDB.BsonValue]::MaxValue
	$m
}

function Get-MD5($Text) {
	$bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
	[guid][System.Security.Cryptography.MD5]::Create().ComputeHash($bytes)
}
