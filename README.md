# Ldbc

LiteDB Cmdlets for PowerShell

***

Ldbc is the PowerShell module based on [LiteDB](https://www.litedb.org).
Ldbc makes LiteDB data and operations PowerShell friendly.

The module works with Windows PowerShell v3-v5 .NET Framework 4.5 and PowerShell Core.

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
    $data = @{Name = 'John'}, @{Name = 'Mary'}
    $data | Add-LiteData $test

    # find using the filter with parameters
    # ~> {"_id":1,"Name":"John"}
    $r = Get-LiteData $test '$.Name = @param1' @{param1 = 'John'}
    "$r"

    # remove one document
    Remove-LiteData $test '$._id = 1'

    # get all remaining documents
    # ~> {"_id":2,"Name":"Mary"}
    $r = Get-LiteData $test
    "$r"
}
```

(b) ditto using just `Invoke-LiteCommand` and LiteDB SQL:

```powershell
Use-LiteDatabase :memory: {
    # add two documents
    Invoke-LiteCommand 'INSERT INTO Test : INT VALUES {Name: "John"}, {Name: "Mary"}' -Quiet

    # find using the filter with parameters
    # ~> {"_id":1,"Name":"John"}
    $r = Invoke-LiteCommand 'SELECT $ FROM Test WHERE $.Name = @param1' @{param1 = 'John'}
    "$r"

    # remove one document
    Invoke-LiteCommand 'DELETE Test WHERE $._id = 1' -Quiet

    # get all remaining documents
    # ~> {"_id":2,"Name":"Mary"}
    $r = Invoke-LiteCommand 'SELECT $ FROM Test'
    "$r"
}
```

**Next steps**

Read cmdlets help with basic examples. Take a look at tests in the repository
for more technical examples.

Read LiteDB [DOCS](https://www.litedb.org/docs/). Some LiteDB API may and
should be used directly. Ldbc is the helper, not replacement.

## Work in progress

Work on module commands and features is in progress, they may change before v1.0.0

Ldbc is going to be aligned with [Mdbc](https://github.com/nightroman/Mdbc).
You may look at it as some sort of the roadmap.

## See also

- [about_Ldbc](https://github.com/nightroman/Ldbc/blob/master/Module/en-US/about_Ldbc.help.txt)
- [Release Notes](https://github.com/nightroman/Ldbc/blob/master/Release-Notes.md)
