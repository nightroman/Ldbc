
Import-Module Ldbc
. .\Class.lib.ps1

function ClassExample {

	enum Severity {
		Information
		Warning
		Error
	}

	class Location {
		[string] $File
		[int] $Line
		[string] ToString() { return '{0}:{1}' -f $this.File, $this.Line }
	}

	class Message {
		[int] $Id
		[string] $Message
		[Severity] $Severity
		[Location] $Location
	}

	Use-LiteDatabase :memory: {
		# get collection with auto id
		$log = Get-LiteCollection Log Int32

		# insert some messages
		$(
			[Message] @{
				Message = 'Obsolete feature.'
				Severity = 'Warning'
				Location = @{ File = 'C:\Scripts\Script1.ps1'; Line = 11 }
			}
			[Message] @{
				Message = 'Not supported feature.'
				Severity = 'Error'
				Location = @{ File = 'C:\Scripts\Script2.ps1'; Line = 99 }
			}
		) | Add-LiteData $log

		# get typed messages back
		Get-LiteData $log -As Message
	}
}

task ClassExample {
	$r = ClassExample
	$r | Out-String
	equals $r.Count 2
	equals $r[0].Id 1
	equals $r[0].Location.Line 11
}

task DbRef {
	$customer = [Customer]@{CustomerId = 1; Name = 'John'}
	$product1 = [Product]@{ProductId = 1; Name = 'Foo'}
	$product2 = [Product]@{ProductId = 2; Name = 'Bar'}
	$order = [Order]@{OrderId = 1; Customer = $customer; Products = $product1, $product2}

	Use-LiteDatabase -Script {
		$customers = Get-LiteCollection customers
		$products = Get-LiteCollection products
		$orders = Get-LiteCollection orders

		$order.Products | Add-LiteData $products
		Add-LiteData $customers $customer
		Add-LiteData $orders $order

		# raw, no refs
		$r = Get-LiteData $orders
		equals "$r" '{"_id":1,"Customer":{"$id":1,"$ref":"customers"},"Products":[{"$id":1,"$ref":"products"},{"$id":2,"$ref":"products"}]}'

		# raw, with refs
		$r = Get-LiteData $orders -Include '$.Customer', '$.Products[*]'
		equals "$r" '{"_id":1,"Customer":{"_id":1,"Name":"John"},"Products":[{"_id":1,"Name":"Foo"},{"_id":2,"Name":"Bar"}]}'

		# typed, no refs
		$r = Get-LiteData $orders -As Order
		equals "$r" '#1 #1  [#1 , #2 ]'

		# typed, with refs
		$r = Get-LiteData $orders -As Order -Include '$.Customer', '$.Products[*]'
		equals "$r" '#1 #1 John [#1 Foo, #2 Bar]'
	}
}
