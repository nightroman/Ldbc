<#
.Synopsis
	Help script (https://github.com/nightroman/Helps)
#>

Import-Module Ldbc
Set-StrictMode -Version 2

$AsParameter = @'
Specifies the type of output objects. The argument is either a type or a type
name or an alias ("PS", "Default"). "PS" is for PSCustomObject. "Default" is
for Ldbc.Dictionary, the PowerShell friendly wrapper of BsonDocument.
'@

$AsOutputs = @(
	@{
		type = 'object, PSCustomObject, Ldbc.Dictionary'
		description = 'Output types depend on the parameter As.'
	}
)

$CollectionNameParameter = @'
The collection name, case insensitive.
'@

$CollectionParameter = @'
The collection instance.
Use Get-LiteCollection in order to get it from a database.
'@

$DatabaseParameter = @'
The database instance. If it is omitted then the variable $Database is expected.
Use New-LiteDatabase or Use-LiteDatabase in order to get the database instance.
'@

$ExpressionHelp = @'
The expression may be string, Ldbc.Expression, or LiteDB.BsonExpression.

An expression with named parameters or indexed arguments is followed by a
parameter dictionary or argument values.

Separate expressions and arguments with commas.
Parenthesis may be used but they are not required.
Array notation @() may be used for multiline expressions.

Examples:

	'.. @x .. @y ..', @{x = 40; y = 80}

	('.. @0 .. @1 ..', 40, 80)

	@(
		'.. @0 .. @1 ..'
		<argument 0>
		<argument 1>
	)
'@

$ParametersParameter = @'
Specifies the expression named parameters (IDictionary) or indexed arguments (IList or object).
'@

$DocumentInputs = @(
	@{
		type = 'PSCustomObject, IDictionary, class'
		description = @'
Document-like objects.

Dictionaries include Hashtable, Ldbc.Dictionary, LiteDB.BsonDocument, etc.

PowerShell classes and .NET complex objects are serialized using LiteDB mappings.
'@
	}
)

$WhereParameter = $(
	'Specifies the filter expression.'
	$ExpressionHelp
)

### Get-LiteData
@{
	command = 'Get-LiteData'
	synopsis = 'Gets data from the collection.'
	description = @'
The cmdlet gets data specified by the parameters from the collection.
'@
	parameters = @{
		Collection = $CollectionParameter
		Where = $WhereParameter
		As = $AsParameter
		ById = @'
Tells to find a document by the specified id.
The cmdlet outputs the found document, if any.
'@
		Count = @'
Tells to count the documents and return the number.
'@
		First = @'
Specifies the number of first documents to be returned.
Non positive values are ignored.
'@
		Last = @'
Specifies the number of last documents to be returned.
Non positive values are ignored.
'@
		Skip = @'
Specifies the number of documents to skip from the beginning or from the end if
Last is specified. Non positive values are ignored.
'@
		OrderBy = @'
Specifies the sort expression.
'@
		Order = @'
Specifies the sort direction, 1: ascending, -1: descending.
'@
		Select = @'
Specifies the projections applied to results.
Note that _id is not automatically included.

Examples:
	Selected field subset: {_id, name, age}
	Renamed or calculated: {Item: name, Total: $.count * $.price}
'@
		Include = @'
Specifies expressions for loading references.

Example: Given $order is the collection of [Order] with references to single
[Customer] and multiple [Product]

	Get-LiteData $orders -As Order -Include 'Customer', 'Products[*]'
'@
	}
	outputs = $AsOutputs
	examples = @(
		@{
			code = {
				Use-LiteDatabase :memory: {
					$test = Get-LiteCollection test

					# add two documents
					$data = @{_id = 1; Name = 'John'}, @{_id = 2; Name = 'Mary'}
					$data | Add-LiteData $test

					# query data using filter with parameters
					Get-LiteData $test ('Name = @Name', @{Name = 'Mary'})

					# query strongly typed data
					class MyData {[int]$Id; [string]$Name}
					Get-LiteData $test -As MyData
				}
			}
			test = {
				$r = . $args[0]
				equals "$($r[0])" '{"_id":2,"Name":"Mary"}'
				equals $r[1].Id 1
				equals $r[1].Name John
			}
		}
	)
	links = @(
		@{ text = 'Add-LiteData' }
		@{ text = 'Set-LiteData' }
		@{ text = 'Remove-LiteData' }
		@{ text = 'Update-LiteData' }
	)
}

### Add-LiteData
@{
	command = 'Add-LiteData'
	synopsis = 'Inserts input documents to the collection.'
	description = @'
The cmdlet inserts input documents to the collection.
One document may be specified as the parameter.
Use the pipeline for several input documents.

For several documents or calls consider using a transaction for better performance.
'@
	parameters = @{
		Collection = $CollectionParameter
		InputObject = 'The input document, see INPUTS.'
		Result = 'Tells to output inserted document ids.'
	}
	inputs = $DocumentInputs
	outputs = @(
		@{
			type = 'none'
			description = 'The cmdlet outputs nothing without the switch Result.'
		}
		@{
			type = 'object'
			description = 'Inserted document ids, if the switch Result is used.'
		}
	)
	examples = @(
		@{
			code = {
				Use-LiteDatabase :memory: {
					# get the collection, add some hashtable
					# (use [ordered] to keep the key order)
					$log = Get-LiteCollection log
					Add-LiteData $log ([ordered]@{
						Message = 'Doing X...'
						Type = 'Info'
						Time = Get-Date
					})

					# get data
					Get-LiteData $log
				}
			}
			test = { . $args[0] }
		}
		@{
			code = {
				Use-LiteDatabase :memory: {
					# get processes as PSCustomObject with some properties
					$data = Get-Process | Select-Object @{n='_id'; e={$_.Id}}, ProcessName, WorkingSet64

					# get the collection and add data
					$test = Get-LiteCollection test
					$data | Add-LiteData $test

					# get data
					Get-LiteData $test
				}
			}
			test = { . $args[0] }
		}
	)
	links = @(
		@{ text = 'Get-LiteData' }
		@{ text = 'Set-LiteData' }
		@{ text = 'Remove-LiteData' }
		@{ text = 'Update-LiteData' }
	)
}

### Set-LiteData
@{
	command = 'Set-LiteData'
	synopsis = 'Replaces old documents in the collection with new input documents.'
	description = @'
The cmdlet replaces old documents in the collection with new input documents.
One document may be specified as the parameter.
Use the pipeline for several input documents.

If the old document does not exist then the new is inserted if the switch Add is used.
Otherwise the new document is ignored.

For several documents or calls consider using a transaction for better performance.
'@
	parameters = @{
		Collection = $CollectionParameter
		InputObject = 'The input document, see INPUTS.'
		Add = @'
Tells to insert the new document if the old does not exist.
'@
		Result = @'
Tells to output
the number of replaced documents (Add is not used) or
the number of added documents (Add is used).
'@
	}
	inputs = $DocumentInputs
	outputs = @(
		@{
			type = 'none'
			description = @'
The cmdlet outputs nothing without the switch Result.
'@
		}
		@{
			type = 'int'
			description = @'
If the switch Result is used,
the number of replaced documents (Add is not used) or
the number of added documents (Add is used).
'@
		}
	)
	examples = @(
		@{
			code = {
				Use-LiteDatabase :memory: {
					$test = Get-LiteCollection test

					# 1 (added)
					Set-LiteData $test @{_id = 1; name = 'John'} -Add -Result
					Get-LiteData $test

					# 1 (updated)
					Set-LiteData $test @{_id = 1; name = 'Mary'} -Result
					Get-LiteData $test
				}
			}
			test = {
				$r = . $args[0]
				equals "$r" '1 {"_id":1,"name":"John"} 1 {"_id":1,"name":"Mary"}'
			}
		}
	)
	links = @(
		@{ text = 'Add-LiteData' }
		@{ text = 'Get-LiteData' }
		@{ text = 'Remove-LiteData' }
		@{ text = 'Update-LiteData' }
	)
}

### Test-LiteData
@{
	command = 'Test-LiteData'
	synopsis = 'Gets true if the query matches any document.'
	description = @'
The cmdlet gets true if the specified query matches any document.
This method does not deserialize data.
'@
	parameters = @{
		Collection = $CollectionParameter
		Where = $WhereParameter
		ById = 'Specifies the document id.'
	}
	outputs = @(
		@{
			type = 'bool'
			description = 'True if the query matches any document.'
		}
	)
}

### Remove-LiteData
@{
	command = 'Remove-LiteData'
	synopsis = 'Removes data from the collection.'
	description = @'
The cmdlet removes documents specified by the filter from the collection.
'@
	parameters = @{
		Collection = $CollectionParameter
		Where = $WhereParameter
		ById = @'
Tells to remove one document by the specified id.
'@
		Result = @'
Tells to output the number of removed documents.
'@
	}
	examples = @(
		@{
			code = {
				Use-LiteDatabase :memory: {
					$test = Get-LiteCollection test

					# add two documents
					$data = @{_id = 1; Name = 'John'}, @{_id = 2; Name = 'Mary'}
					$data | Add-LiteData $test

					# remove data using filter with parameters
					Remove-LiteData $test ('Name = @Name', @{Name = 'Mary'})
					Get-LiteData $test
				}
			}
			test = {
				$r = . $args[0]
				equals "$r" '{"_id":1,"Name":"John"}'
			}
		}
	)
	links = @(
		@{ text = 'Add-LiteData' }
		@{ text = 'Get-LiteData' }
		@{ text = 'Set-LiteData' }
		@{ text = 'Update-LiteData' }
	)
}

### Update-LiteData
@{
	command = 'Update-LiteData'
	synopsis = 'Updates documents in the collection.'
	description = @'
The cmdlet updates the documents specified by the filter expression using the
update expression.
'@
	parameters = @{
		Collection = $CollectionParameter
		Where = $WhereParameter
		ById = 'Specifies the document id.'
		Update = $(
			'Specifies the transformation expression.'
			$ExpressionHelp
		)
		Result = 'Tells to output the number of updated documents.'
	}
	outputs = @(
		@{
			type = '[int]'
			description = 'The number of updated documents.'
		}
	)
	examples = @(
		@{
			code = {
				Use-LiteDatabase :memory: {
					$test = Get-LiteCollection test

					# add data
					Add-LiteData $test @{_id = 1; Name = 'John'}

					# change Name using filter and update with parameters
					$filter = 'Name = @Name', @{Name = 'John'}
					$update = '{Name : @Name}', @{Name = 'Mary'}
					Update-LiteData $test $filter $update

					Get-LiteData $test
				}
			}
			test = {
				$r = . $args[0]
				equals "$r" '{"_id":1,"Name":"Mary"}'
			}
		}
	)
	links = @(
		@{ text = 'Add-LiteData' }
		@{ text = 'Get-LiteData' }
		@{ text = 'Set-LiteData' }
		@{ text = 'Remove-LiteData' }
	)
}

### Invoke-LiteCommand
@{
	command = 'Invoke-LiteCommand'
	synopsis = 'Invokes the LiteDB SQL command and gets results.'
	description = @'
The cmdlet invokes the command with optional parameters (if the command
supports parameters).
'@
	parameters = @{
		Command = 'Specifies the LiteDB SQL command.'
		Database = $DatabaseParameter
		Parameters = $ParametersParameter
		As = $AsParameter
		Quiet = 'Tells to omit the command output.'
		Collection = 'The output [ref] of the command collection name.'
	}
	outputs = $AsOutputs
	examples = @(
		@{
			title = 'See README examples.'
		}
	)
	links = @(
		@{ text = 'LiteDB SQL'; URI = 'https://www.litedb.org/api/' }
	)
}

### $DatabaseBase
$DatabaseBase = @{
	parameters = @{
		ConnectionString = @'
Specifies the LiteDB connection string.
'@
		Stream = @'
Specifies the stream for reading and writing as the database.
'@
	}
}

### New-LiteDatabase
Merge-Helps $DatabaseBase @{
	command = 'New-LiteDatabase'
	synopsis = 'Opens new or existing database and creates the database instance.'
	description = @'
The cmdlet opens new or existing database and returns the database instance
for further operations. The returned instance must be closed by Dispose().
Consider using Use-LiteDatabase instead for more automatic disposal.
'@
	outputs = @(
		@{
			type = 'LiteDB.LiteDatabase'
			description = 'The database instance. Must be disposed after use.'
		}
	)
	examples = @(
		@{
			code = {
				$Database = New-LiteDatabase :memory:
				try {
					# working with $Database...
					$Database
				}
				finally {
					$Database.Dispose()
				}
			}
			remarks = 'Classic try/finally pattern for disposing objects.'
			test = {
				$r = . $args[0]
				assert ($r -is [LiteDB.LiteDatabase])
			}
		}
	)
	links = @(
		@{ text = 'Use-LiteDatabase' }
	)
}

### Use-LiteDatabase
Merge-Helps $DatabaseBase @{
	command = 'Use-LiteDatabase'
	synopsis = 'Opens the database, invokes the script, and closes the database.'
	description = @'
The cmdlet opens new or existing database, creates the variable $Database for
it, and invokes the specified script. When the script completes or fails the
database is automatically disposed.

Use the switch Transaction in order to invoke multiple changes in a transaction.
Note that using transactions may significantly improve performance as well.
'@
	parameters = @{
		Script = 'The script operating on the database.'
		Transaction = @'
Tells to use a transaction.
If the script completes the transaction is committed.
If the script terminates due to an error the transaction is aborted.
'@
	}
	outputs = @(
		@{
			description = 'Output of the script.'
		}
	)
	examples = @(
		@{
			code = {
				Use-LiteDatabase :memory: {
					# working with $Database...
					$Database
				}
			}
			test = {
				$r = . $args[0]
				assert ($r -is [LiteDB.LiteDatabase])
			}
		}
	)
	links = @(
		@{ text = 'New-LiteDatabase' }
	)
}

### Use-LiteTransaction
@{
	command = 'Use-LiteTransaction'
	synopsis = 'Invokes the script operating on data with a transaction.'
	description = @'
The cmdlet creates a new transaction or continues using the existing in the
same thread. Then it invokes the specified script. The new transaction is
automatically committed or aborted depending on the script completion or
failure.

If you use a single transaction then `Use-LiteDatabase -Transaction` may do the
same trick as using this cmdlet.

NOTE: Using a transaction for multiple changes may improve overall performance.
'@
	parameters = @{
		Database = $DatabaseParameter
		Script = 'The script operating on data in the transaction.'
	}
	outputs = @(
		@{
			description = 'Output of the script.'
		}
	)
	examples = @(
		@{
			code = {
				Use-LiteDatabase :memory: {
					Use-LiteTransaction {
						# working with $Database in transaction...
						$Database
					}
				}

				# Or you may tell to use transaction like this:
				# Use-LiteDatabase :memory: -Transaction {...}
			}
			test = {
				$r = . $args[0]
				assert ($r -is [LiteDB.LiteDatabase])
			}
		}
	)
	links = @(
		@{ text = 'New-LiteDatabase' }
		@{ text = 'Use-LiteDatabase' }
	)
}

### Get-LiteCollection
@{
	command = 'Get-LiteCollection'
	synopsis = 'Gets the collection instance.'
	description = @'
The cmdlet gets the collection instance by its name from the specified or
default database.
'@
	parameters = @{
		CollectionName = $CollectionNameParameter
		AutoId = 'The automatic identifier data type.'
		Database = $DatabaseParameter
	}
	outputs = @(
		@{
			type = 'LiteDB.ILiteCollection[LiteDB.BsonDocument]'
			description = 'The collection instance.'
		}
	)
	examples = @(
		@{
			code = {
				Use-LiteDatabase :memory: {
					# get the collection
					$MyCollection = Get-LiteCollection MyCollection

					# use it...
					$MyCollection
				}
			}
			test = {
				$r = . $args[0]
				assert ($r -is [LiteDB.LiteCollection[LiteDB.BsonDocument]])
			}
		}
	)
	links = @(
		@{ text = 'New-LiteDatabase' }
		@{ text = 'Use-LiteDatabase' }
	)
}

### Register-LiteType
@{
	command = 'Register-LiteType'
	synopsis = 'Registers custom type serialization.'
	description = @'
The cmdlet allows custom serialization definition using script blocks.
'@
	parameters = @{
		Type = @'
Specifies the custom serialized type.
'@
		Serialize = @'
The script which converts the live object $_ to the object to be serialized.
'@
		Deserialize = @'
The script which converts the deserialized object $_ to the live object.
'@
	}
	examples = @(
		@{
			code = {
				# save Version as string
				Register-LiteType ([Version]) {
					$_.ToString()
				} {
					[version]$_
				}

				# test
				$data1 = [version]'1.2.3'
				$saved = [LiteDB.BsonMapper]::Global.Serialize([version], $data1)
				$data2 = [LiteDB.BsonMapper]::Global.Deserialize([version], $saved)
				$data2 -eq $data1
			}
			test = {
				assert (. $args[0])
			}
		}
	)
}
