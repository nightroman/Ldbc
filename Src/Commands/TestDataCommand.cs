
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using LiteDB;
using System.Management.Automation;

namespace Ldbc.Commands
{
	[Cmdlet(VerbsDiagnostic.Test, "LiteData")]
	[OutputType(typeof(bool))]
	public sealed class TestDataCommand : Abstract
	{
		[Parameter(Position = 0, Mandatory = true)]
		public ILiteCollection<BsonDocument> Collection { get; set; }

		[Parameter(Position = 1)]
		public object Where { set { _Where = Expression.Create(value); } }
		Expression _Where;

		protected override void BeginProcessing()
		{
			var yes = Collection.Exists(_Where.BsonExpression);
			WriteObject(yes);
		}
	}
}
