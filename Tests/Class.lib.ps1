<#
.Synopsis
	PowerShell classes for tests with -As and -Include.

.Description
	Tip: Define types with Bson* attributes in a separate script and dot-source
	it to the consumer script after `Import-Module Ldbc`. If you define classes
	right in the consumer script PowerShell may fail to parse Bson* attributes.

	For Bson* serialization attributes and type mapping, see:
	https://www.litedb.org/docs/object-mapping/
	https://www.litedb.org/docs/dbref/

	See Classes.test.ps1 for tests with this script classes.
#>

# To avoid long type names
using namespace LiteDB
using namespace System.Collections.Generic

class Customer {
	[int] $CustomerId
	[string] $Name
	[string] ToString() {return '#{0} {1}' -f $this.CustomerId, $this.Name}
}

class Product {
	[int] $ProductId
	[string] $Name
	[string] ToString() {return '#{0} {1}' -f $this.ProductId, $this.Name}
}

class Order {
	[int] $OrderId
	[BsonRef("customers")]
	[Customer] $Customer
	[BsonRef("products")]
	[Product[]] $Products
	[string] ToString() {return '#{0} {1} [{2}]' -f $this.OrderId, $this.Customer, ($this.Products -join ', ')}
}
