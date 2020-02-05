﻿
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using System.Collections.Generic;
using System.Management.Automation;

namespace Ldbc.Commands
{
	[Cmdlet(VerbsOther.Use, "LiteDatabase", DefaultParameterSetName = nsConnectionString)]
	public sealed class UseDatabaseCommand : NewDatabaseCommand
	{
		[Parameter(Position = 1, Mandatory = true)]
		public ScriptBlock Script { get; set; }

		protected override void BeginProcessing()
		{
			using (var database = CreateDatabase())
			{
				var vars = new List<PSVariable>() { new PSVariable(Actor.DatabaseVariable, database) };
				try
				{
					var result = Script.InvokeWithContext(null, vars);
					foreach (var item in result)
						WriteObject(item);
				}
				catch(RuntimeException exn)
				{
					ThrowWithPositionMessage(exn);
				}
			}
		}
	}
}