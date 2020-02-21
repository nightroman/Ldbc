
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using LiteDB;
using System.Management.Automation;

namespace Ldbc.Commands
{
	[Cmdlet(VerbsDiagnostic.Test, "LiteData", DefaultParameterSetName = nsWhere)]
	[OutputType(typeof(bool))]
	public sealed class TestDataCommand : Abstract
	{
		const string nsWhere = "Where";
		const string nsById = "ById";

		[Parameter(Position = 0, Mandatory = true)]
		public ILiteCollection<BsonDocument> Collection { get; set; }

		[Parameter(Position = 1, ParameterSetName = nsWhere)]
		public object Where { set { _Where = Expression.Input(value); } }
		BsonExpression _Where;

		[Parameter(Mandatory = true, ParameterSetName = nsById)]
		public object ById { set { _Where = WhereIdExpression.Input(value); } }

		protected override void BeginProcessing()
		{
			var yes = Collection.Exists(_Where);
			WriteObject(yes);
		}
	}
}
