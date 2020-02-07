
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using LiteDB;
using System.Management.Automation;

namespace Ldbc.Commands
{
	[Cmdlet(VerbsCommon.Get, "LiteData")]
	[OutputType(typeof(Dictionary))]
	public sealed class GetDataCommand : Abstract
	{
		[Parameter(Position = 0, Mandatory = true)]
		public ILiteCollection<BsonDocument> Collection { get; set; }

		[Parameter(Position = 1)]
		public object[] Filter { set { _Filter = Expression.Create(value); } }
		Expression _Filter;

		protected override void BeginProcessing()
		{
			if (_Filter == null)
			{
				foreach (var doc in Collection.FindAll())
					WriteObject(Actor.ToObject(doc));
			}
			else
			{
				foreach (var doc in Collection.Find(_Filter.BsonExpression))
					WriteObject(Actor.ToObject(doc));
			}
		}
	}
}
