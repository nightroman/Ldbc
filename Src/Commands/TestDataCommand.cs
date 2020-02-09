
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
		public object[] Filter { set { _Filter = Expression.Create(value); } }
		Expression _Filter;

		protected override void BeginProcessing()
		{
			var yes = Collection.Exists(_Filter.BsonExpression);
			WriteObject(yes);
		}
	}
}
