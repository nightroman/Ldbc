# Ldbc Release Notes

## v0.7.1

LiteDB 5.0.4

Tidy up and simplify data conversion to documents.

## v0.7.0

Removed parameters `Bulk`. It turns out using transactions gives practically
the same performance improvement as using bulk operations (apparently due to
bulk automatic transactions). Besides, in Ldbc bulks require more memory.

New switch `Transaction` of `Use-LiteDatabase` tells to use a transaction.
This makes using transactions easier, e.g. for better "bulks" performance.

## v0.6.6

Temporary workaround for inserting documents with default ids which types are
different from the collection auto id type. So far it was not possible to add
ids 0, 0L, Guid.Empty, ObjectId.Empty.

## v0.6.5

Improve help, reflect recent changes.

## v0.6.4

- `Update-LiteData` - new parameter `ById`.
- `Get-LiteData` - `Order` without `OrderBy` implies `_id`.

## v0.6.3

LiteDB 5.0.3

`Test-LiteData` - new parameter `ById`.

Parametrized expressions - support both parameters and arguments notations:

```powershell
# expression followed by IDictionary with named parameters
X-LiteData .. -Where ('x = @x AND y = @y', @{x = 1; y = 2})

# expression followed by indexed positional arguments
X-LiteData .. -Where ('x = @0 AND y = @1', 1, 2)
```

## v0.6.2

`Get-LiteData`

- New parameter `Include` for references.
- Parameter set `ById` includes `Select`.

## v0.6.1

`Get-LiteData`, `Remove-LiteData` - new parameter `ById`.

## v0.6.0

New cmdlet `Register-LiteType` for PowerShell friendly custom serialization.

Renamed parameters `Filter` to `Where` (~ LiteDB and PowerShell style).

Simplified internal data conversion to documents.

Work around [#1483](https://github.com/mbdavid/LiteDB/issues/1483).

## v0.5.0

`Add-LiteData`, `Set-LiteData` serialize complex types using the default mapper.
As a result, in particular, it is now possible to work with PowerShell classes.
See examples in [Class.test.ps1](https://github.com/nightroman/Ldbc/blob/master/Tests/Class.test.ps1).

Parameters `As` of `Get-LiteData` and `Invoke-LiteCommand` support all suitable
types, including PowerShell classes. For now, the default global mapper is used.

Added implicit converters to wrapped types to `Ldbc.Dictionary` and `Ldbc.Collection`.

## v0.4.2

- `Get-LiteData` - new parameters `Select`, `OrderBy`, `Order`
- `Invoke-LiteCommand` - new parameters `As` (and `[ref] Collection` for special cases)

## v0.4.1

- `*-LiteDatabase` - resolve relative file paths
- `Ldbc.Dictionary.Print()` - improve JSON formatting

## v0.4.0

LiteDB 5.0.2

`Get-LiteData`

- New parameters: `First`, `Last`, `Skip`.
- New parameter `As`, for now just "PS" for PS custom objects.

`Add-LiteData`, `Set-LiteData`

- Rename `Batch` switches to more idiomatic `Bulk`.

## v0.3.0

- New cmdlet `Test-LiteData`
- New switch `Count` of `Get-LiteData`
- New switch `Batch` of `Add-LiteData`, `Set-LiteData` (~50% faster)

## v0.2.0

- New cmdlets `Set-LiteData`, `Update-LiteData`
- New helper `Ldbc.Expression`, wrapper of `LiteDB.BsonExpression`
- Cmdlet expression parameters are specified as `object[]`, see help

## v0.1.0

- New cmdlet `Get-LiteCollection`
- `Add-LiteData`, `Get-LiteData`, `Remove-LiteData` use collection instances instead of names

## v0.0.1

LiteDB 5.0.1

Cmdlets:

- Add-LiteData
- Get-LiteData
- Invoke-LiteCommand
- New-LiteDatabase
- Remove-LiteData
- Use-LiteDatabase
- Use-LiteTransaction
