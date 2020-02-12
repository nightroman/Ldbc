
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using LiteDB;
using System;
using System.Management.Automation;

namespace Ldbc.Commands
{
	[Cmdlet(VerbsLifecycle.Invoke, "LiteCommand")]
	[OutputType(typeof(Dictionary))]
	public sealed class InvokeCommandCommand : Abstract
	{
		[Parameter(Position = 0, Mandatory = true)]
		public string Command { get; set; }

		[Parameter(Position = 1)]
		public object Parameters { get; set; }

		[Parameter]
		public ILiteDatabase Database { get; set; }

		[Parameter]
		public SwitchParameter Quiet { get; set; }

		[Parameter]
		public object As { get; set; }

		[Parameter]
		public PSReference Collection { get; set; }

		protected override void BeginProcessing()
		{
			if (Database == null)
				Database = ResolveDatabase();

			var param = new InputParameters(Parameters);

			using (var reader = param.Arguments == null ? Database.Execute(Command, param.Parameters) : Database.Execute(Command, param.Arguments))
			{
				if (Collection != null)
					Collection.Value = reader.Collection;

				if (Quiet)
					return;

				// case: no As
				if (As == null)
				{
					while (reader.Read())
						WriteObject(Actor.ToObject(reader.Current));
					return;
				}

				if (As is string s && s.Equals("PS", StringComparison.OrdinalIgnoreCase))
				{
					while (reader.Read())
					{
						var value = reader.Current;
						switch (value.Type)
						{
							case BsonType.Document:
								WriteObject(PSObjectSeializer.ReadCustomObject(value.AsDocument));
								break;
							case BsonType.Array:
								WriteObject(PSObjectSeializer.ReadArray(value.AsArray));
								break;
							default:
								WriteObject(Actor.ToObject(value));
								break;
						}
					}
					return;
				}

				throw new PSNotSupportedException("Parameter As must be just 'PS', for now.");
			}
		}
	}
}
