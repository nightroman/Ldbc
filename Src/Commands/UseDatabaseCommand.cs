
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using System.Collections.Generic;
using System.Management.Automation;

namespace Ldbc.Commands
{
	[Cmdlet(VerbsOther.Use, "LiteDatabase", DefaultParameterSetName = NSConnectionString)]
	public sealed class UseDatabaseCommand : NewDatabaseCommand
	{
		[Parameter(Position = 1, Mandatory = true)]
		public ScriptBlock Script { get; set; }

		[Parameter]
		public SwitchParameter Transaction { get; set; }

		protected override void BeginProcessing()
		{
			using (var database = CreateDatabase())
			{
				var vars = new List<PSVariable>() { new PSVariable(Actor.DatabaseVariable, database) };
				var trans = Transaction ? database.BeginTrans() : false;
				try
				{
					var result = Script.InvokeWithContext(null, vars);
					foreach (var item in result)
						WriteObject(item);

					if (trans)
						database.Commit();
				}
				catch (RuntimeException exn)
				{
					ThrowWithPositionMessage(exn);
				}
			}
		}
	}
}
