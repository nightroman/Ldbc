
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using LiteDB;
using System.Management.Automation;

namespace Ldbc.Commands
{
	[Cmdlet(VerbsCommon.Remove, "LiteData")]
	public sealed class RemoveDataCommand : Abstract
	{
		[Parameter(Position = 0, Mandatory = true)]
		public string CollectionName { get; set; }

		[Parameter(Position = 1, Mandatory = true)]
		public string Filter { get; set; }

		[Parameter(Position = 2)]
		public object Parameters { get; set; }

		[Parameter]
		public ILiteDatabase Database { get; set; }

		[Parameter]
		public SwitchParameter Result { get; set; }

		protected override void BeginProcessing()
		{
			if (Database == null)
				Database = ResolveDatabase();

			var collection = Database.GetCollection(CollectionName);

			var param = new InputParameters(Parameters);
			var deletedCount = collection.DeleteMany(param.Expression(Filter));
			if (Result)
				WriteObject(deletedCount);
		}
	}
}
