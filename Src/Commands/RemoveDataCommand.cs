
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
		public ILiteCollection<BsonDocument> Collection { get; set; }

		[Parameter(Position = 1, Mandatory = true)]
		public object Where { set { _Where = Expression.Create(value); } }
		Expression _Where;

		[Parameter]
		public SwitchParameter Result { get; set; }

		protected override void BeginProcessing()
		{
			var count = Collection.DeleteMany(_Where.BsonExpression);
			if (Result)
				WriteObject(count);
		}
	}
}
