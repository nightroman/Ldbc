
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using LiteDB;
using System.Management.Automation;

namespace Ldbc.Commands
{
	[Cmdlet(VerbsCommon.Remove, "LiteData", DefaultParameterSetName = nsMany)]
	public sealed class RemoveDataCommand : Abstract
	{
		const string nsMany = "Many";
		const string nsById = "ById";

		[Parameter(Position = 0, Mandatory = true)]
		public ILiteCollection<BsonDocument> Collection { get; set; }

		[Parameter(Position = 1, Mandatory = true, ParameterSetName = nsMany)]
		public object Where { set { _Where = Expression.Create(value); } }
		Expression _Where;

		[Parameter(Mandatory = true, ParameterSetName = nsById)]
		public object ById { get; set; }

		[Parameter]
		public SwitchParameter Result { get; set; }

		protected override void BeginProcessing()
		{
			if (ById == null)
			{
				var count = Collection.DeleteMany(_Where.BsonExpression);
				if (Result)
					WriteObject(count);
			}
			else
			{
				var deleted = Collection.Delete(Actor.ToBsonValue(ById));
				if (Result)
					WriteObject(deleted ? 1 : 0);
			}
		}
	}
}
