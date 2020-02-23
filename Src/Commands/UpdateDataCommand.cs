
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using LiteDB;
using System.Management.Automation;

namespace Ldbc.Commands
{
	[Cmdlet(VerbsData.Update, "LiteData", DefaultParameterSetName = nsWhere)]
	public sealed class UpdateDataCommand : Abstract
	{
		const string nsWhere = "Where";
		const string nsById = "ById";

		[Parameter(Position = 0, Mandatory = true)]
		public ILiteCollection<BsonDocument> Collection { get; set; }

		[Parameter(Position = 1, Mandatory = true, ParameterSetName = nsWhere)]
		public object Where { set { _Where = Expression.Input(value); } }
		BsonExpression _Where;

		[Parameter(Position = 2, Mandatory = true)]
		public object Update { set { _Update = Expression.Input(value); } }
		BsonExpression _Update;

		[Parameter(Mandatory = true, ParameterSetName = nsById)]
		public object ById { set { _Where = WhereIdExpression.Input(value); } }

		[Parameter]
		public SwitchParameter Result { get; set; }

		protected override void BeginProcessing()
		{
			var count = Collection.UpdateMany(_Update, _Where);
			if (Result)
				WriteObject(count);
		}
	}
}
