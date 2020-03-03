# Ldbc

LiteDB Cmdlets for PowerShell

***

Ldbc is the PowerShell module with [LiteDB](https://www.litedb.org),
a small, fast and lightweight .NET NoSQL embedded database.

The module works with Windows PowerShell v3-v5 .NET Framework 4.5 and PowerShell Core.

Some LiteDB features:

- Single datafile
- ACID transactions
- Store files and stream data
- Cross collections references
- Recovery after writing failures
- Mapping classes to documents

Ldbc makes LiteDB operations and data PowerShell friendly. You can store and
retrieve hashtables and dictionaries, PowerShell classes and custom objects,
.NET complex types. Operate on data using specialized cmdlets or LiteDB SQL.

## Quick start

**Step 1:** Get and install

Ldbc is published as the PSGallery module [Ldbc](https://www.powershellgallery.com/packages/Ldbc).

You can install the module by this command:

```powershell
Install-Module Ldbc
```

**Step 2:** In a PowerShell command prompt import the module:

```powershell
Import-Module Ldbc
```

**Step 3:** Take a look at help and available commands:

```powershell
help about_Ldbc
Get-Command -Module Ldbc
help Use-LiteDatabase -Full
```

**Step 4:** Try add, get, remove operations with a memory database

(a) using `Add-LiteData`, `Get-LiteData`, `Remove-LiteData`:

```powershell
Use-LiteDatabase :memory: {
    # get the collection, specify auto id
    $test = Get-LiteCollection Test Int32

    # add two documents
    @{Name = 'John'}, @{Name = 'Mary'} | Add-LiteData $test

    # find using filter with an argument
    $r = Get-LiteData $test -Where 'Name = @0', John
    "$r" # {"_id":1,"Name":"John"}

    # remove one by _id
    Remove-LiteData $test -ById 1

    # get all documents
    $r = Get-LiteData $test
    "$r" # {"_id":2,"Name":"Mary"}
}
```

(b) ditto using just `Invoke-LiteCommand` and LiteDB SQL:

```powershell
Use-LiteDatabase :memory: {
    # add two documents
    Invoke-LiteCommand 'INSERT INTO Test : INT VALUES {Name: "John"}, {Name: "Mary"}' -Quiet

    # find using WHERE with parameters
    $r = Invoke-LiteCommand 'SELECT $ FROM Test WHERE Name = @param1' @{param1 = 'John'}
    "$r" # {"_id":1,"Name":"John"}

    # remove using WHERE with parameters
    Invoke-LiteCommand 'DELETE Test WHERE _id = @_id' @{_id = 1} -Quiet

    # get all documents
    $r = Invoke-LiteCommand 'SELECT $ FROM Test'
    "$r" # {"_id":2,"Name":"Mary"}
}
```

(c) store and retrieve PowerShell custom objects

```powershell
Use-LiteDatabase :memory: {
    # get the collection
    $test = Get-LiteCollection Test

    # get PS objects, select some properties, insert
    Get-ChildItem | Select-Object Name, Mode, Length | Add-LiteData $test

    # get back PS custom objects
    Get-LiteData $test -As PS
}
```

**Next steps**

Read cmdlets help with basic examples. Take a look at tests in the repository
for more technical examples.

Read LiteDB [DOCS](https://www.litedb.org/docs/). Some LiteDB API may and
should be used directly. Ldbc is the helper, not replacement.

## LiteDB methods and module commands

| LiteDB | Module  | Output
| :----- | :-----  | :-----
| **Database** | |
| LiteDatabase | New-LiteDatabase | database (needs Dispose)
| LiteDatabase | Use-LiteDatabase {..} | $Database (auto Dispose)
| GetCollection | Get-LiteCollection | collection instance
| Execute | Invoke-LiteCommand | values, documents
| BeginTrans | Use-LiteTransaction {..} | ..
| + Commit | (success) |
| + Rollback | (failure) |
| **Collection** | |
| Count | Get-LiteData -Count | count
| Exists | Test-LiteData | true or false
| Find* | Get-LiteData | documents
| Insert | Add-LiteData | none, id, count
| Update | Set-LiteData | none, count
| Upsert | Set-LiteData -Add | none, count
| UpdateMany | Update-LiteData | none, count
| DeleteMany | Remove-LiteData | none, count
| **Misc** | |
| RegisterType | Register-LiteType | none

## Work in progress

Work on module commands and features is in progress, they may change before v1.0.0

## See also

- [Ldbc Release Notes](https://github.com/nightroman/Ldbc/blob/master/Release-Notes.md)
- [about_Ldbc.help.txt](https://github.com/nightroman/Ldbc/blob/master/Module/en-US/about_Ldbc.help.txt)
- [Mdbc, similar project for MongoDB](https://github.com/nightroman/Mdbc)
