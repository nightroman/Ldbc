# Ldbc Release Notes

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
