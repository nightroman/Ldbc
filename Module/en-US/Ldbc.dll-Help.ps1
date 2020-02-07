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
Specifies the filter expression.
'@

$ParametersParameter = @'
Specifies the expression named parameters (IDictionary) or indexed arguments (IList or object).
'@

### Add-LiteData
@{
	command = 'Add-LiteData'
	synopsis = 'Inserts data to the collection.'
	description = @'
The cmdlet inserts input documents to the collection.
One document may be specified as the parameter.
Use the pipeline for several input documents.
'@
	parameters = @{
		Collection = $CollectionParameter
		InputObject = 'The input document.'
		Result = 'Tells to output document _id values.'
	}
	inputs = @(
		@{
			type = 'IDictionary, Ldbc.Dictionary, LiteDB.BsonDocument, PSCustomObject, ...'
			description = 'Document-like objects.'
		}
	)
	outputs = @(
		@{
			type = 'object'
			description = 'None or _id values.'
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
		@{ text = 'New-LiteDatabase' }
		@{ text = 'Use-LiteDatabase' }
		@{ text = 'Get-LiteCollection' }
	)
}

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
		Parameters = $ParametersParameter
	}
	outputs = @(
		@{
			type = 'Ldbc.Dictionary'
			description = 'PowerShell friendly wrapper of BsonDocument.'
		}
	)
	examples = @(
		@{
			#title = ''
			#introduction = ''
			code = {
			}
			remarks = ''
			test = { . $args[0] }
		}
	)
	links = @(
		@{ text = ''; URI = '' }
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
		Parameters = $ParametersParameter
		Result = 'Tells to output the number of removed documents.'
	}
	examples = @(
		@{
			#title = ''
			#introduction = ''
			code = {
			}
			remarks = ''
			test = { . $args[0] }
		}
	)
	links = @(
		@{ text = ''; URI = '' }
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
		Quiet = 'Tells not to output results.'
	}
	outputs = @(
		@{
			type = 'object, Ldbc.Dictionary'
			description = 'The command result objects.'
		}
	)
	examples = @(
		@{
			#title = ''
			#introduction = ''
			code = {
			}
			remarks = ''
			test = { . $args[0] }
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
				}
				finally {
					$Database.Dispose()
				}
			}
			remarks = 'Classic try/finally pattern for disposing objects.'
			test = { . $args[0] }
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
				}
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
						# working with $Database...
					}
				}
			}
			test = { . $args[0] }
		}
	)
	links = @(
		@{ text = ''; URI = '' }
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
					$collection = Get-LiteCollection MyCollection
					Get-LiteData $collection
				}
			}
			test = { . $args[0] }
		}
	)
	links = @(
		@{ text = 'New-LiteDatabase' }
		@{ text = 'Use-LiteDatabase' }
	)
}
