
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
		public object As { set { _As = new ParameterAs(value); } }
		ParameterAs _As;

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

				var convert = ParameterAs.GetConvert(_As);
				while (reader.Read())
				{
					var value = reader.Current;
					switch (value.Type)
					{
						case BsonType.Document:
							WriteObject(convert(value.AsDocument));
							break;
						case BsonType.Array:
							throw new NotImplementedException("TODO BsonType.Array");
						default:
							WriteObject(Actor.ToObject(value));
							break;
					}
				}
			}
		}
	}
}
