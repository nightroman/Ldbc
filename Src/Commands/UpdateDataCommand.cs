
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using LiteDB;
using System.Management.Automation;

namespace Ldbc.Commands
{
	[Cmdlet(VerbsData.Update, "LiteData")]
	public sealed class UpdateDataCommand : Abstract
	{
		[Parameter(Position = 0, Mandatory = true)]
		public ILiteCollection<BsonDocument> Collection { get; set; }

		[Parameter(Position = 1, Mandatory = true)]
		public object[] Filter { set { _Filter = Expression.Create(value); } }
		Expression _Filter;

		[Parameter(Position = 2, Mandatory = true)]
		public object[] Update { set { _Update = Expression.Create(value); } }
		Expression _Update;

		[Parameter]
		public SwitchParameter Result { get; set; }

		protected override void BeginProcessing()
		{
			var count = Collection.UpdateMany(_Update.BsonExpression, _Filter.BsonExpression);
			if (Result)
				WriteObject(count);
		}
	}
}
