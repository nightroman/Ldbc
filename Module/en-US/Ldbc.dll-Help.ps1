<#
.Synopsis
	Help script (https://github.com/nightroman/Helps)
#>

Import-Module Ldbc
Set-StrictMode -Version 2

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

$FilterParameter = @'
Specifies the filter expression and optional parameters dictionary separated by a comma.

The expression is either a string or existing Ldbc.Expression or LiteDB.BsonExpression.
'@

$ParametersParameter = @'
Specifies the expression named parameters (IDictionary) or indexed arguments (IList or object).
'@

$DocumentInputs = @(
	@{
		type = 'PSCustomObject, IDictionary (Hashtable, Ldbc.Dictionary, LiteDB.BsonDocument, ...), ...'
		description = 'Document-like objects.'
	}
)

$BatchParameter = @'
Tells to collect all input data and process as a batch.
This works faster and provides an automatic transaction.
But it may require more memory and get less information.
'@

### Get-LiteData
@{
	command = 'Get-LiteData'
	synopsis = 'Gets data from the collection.'
	description = @'
The cmdlets gets all or specified by the filter documents from the collection.
'@
	parameters = @{
		Collection = $CollectionParameter
		Filter = $FilterParameter
		Count = 'Tells to count the documents and return the number.'
	}
	outputs = @(
		@{
			type = 'Ldbc.Dictionary'
			description = 'PowerShell friendly wrapper of BsonDocument.'
		}
	)
	examples = @(
		@{
			code = {
				Use-LiteDatabase :memory: {
					$test = Get-LiteCollection test

					# add two documents
					$data = @{_id = 1; Name = 'John'}, @{_id = 2; Name = 'Mary'}
					$data | Add-LiteData $test

					# query data using filter with parameters
					Get-LiteData $test ('$.Name = @Name', @{Name = 'Mary'})
				}
			}
			test = {
				$r = . $args[0]
				equals "$r" '{"_id":2,"Name":"Mary"}'
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
'@
	parameters = @{
		Collection = $CollectionParameter
		InputObject = 'The input document.'
		Batch = $BatchParameter
		Result = 'Tells to output document _id values or document count.'
	}
	inputs = $DocumentInputs
	outputs = @(
		@{
			type = '[object]'
			description = 'None, _id values, document count.'
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

If the old document does not exist then the new is added if Add is set.
'@
	parameters = @{
		Collection = $CollectionParameter
		InputObject = 'The input document.'
		Add = @'
Tells to add the new document if the old does not exist.'
'@
		Batch = $BatchParameter
		Result = @'
Tells to output
the number of replaced documents (Add is not set) or
the number of added documents (Add is set).
'@
	}
	inputs = $DocumentInputs
	outputs = @(
		@{
			type = '[int]'
			description = @'
The number of replaced documents (Add is not set) or
the number of added documents (Add is set).
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
	synopsis = 'Gets true if the query returns any document.'
	description = @'
The cmdlet gets true if the specified query returns any document.
This method does not deserialize any document.
'@
	parameters = @{
		Collection = $CollectionParameter
		Filter = $FilterParameter
	}
	outputs = @(
		@{
			type = '[bool'
			description = 'True if the query returns any document.'
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
		Filter = $FilterParameter
		Result = 'Tells to output the number of removed documents.'
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
					Remove-LiteData $test ('$.Name = @Name', @{Name = 'Mary'})
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
		Filter = $FilterParameter
		Update = 'Specifies the transformation expression.'
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
					$filter = '$.Name = @Name', @{Name = 'John'}
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
		Quiet = 'Tells to omit the command output.'
	}
	outputs = @(
		@{
			type = 'object, Ldbc.Dictionary'
			description = 'The command result objects.'
		}
	)
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
'@
	parameters = @{
		Script = 'The script operating on the database.'
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
