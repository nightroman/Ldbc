
Import-Module Ldbc

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
