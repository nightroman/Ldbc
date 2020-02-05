<#
.Synopsis
	Help script (https://github.com/nightroman/Helps)
#>

Import-Module Ldbc
Set-StrictMode -Version 2

$CollectionNameParameter = @'
Specifies the collection name (case insensitive).
'@

$DatabaseParameter = @'
Specifies the database. If it is omitted then the variable $Database is expected.
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
Many documents are provided via pipeline.
'@
	parameters = @{
		AutoId = 'Defines the automatic identifier data type.'
		CollectionName = $CollectionNameParameter
		Database = $DatabaseParameter
		InputObject = 'Input document(s).'
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

### Get-LiteData
@{
	command = 'Get-LiteData'
	synopsis = 'Gets data from the collection.'
	description = @'
The cmdlets gets all or specified by the filter documents from the collection.
'@
	parameters = @{
		CollectionName = $CollectionNameParameter
		Database = $DatabaseParameter
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
		CollectionName = $CollectionNameParameter
		Database = $DatabaseParameter
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
				$Database = New-LiteDatabase "MyDB.LiteDB"
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
				Use-LiteDatabase "MyDB.LiteDB" {
					# working with $Database...
				}
			}
			test = { . $args[0] }
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
				Use-LiteDatabase "MyDB.LiteDB" {
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
