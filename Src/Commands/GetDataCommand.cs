
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
		public string Filter { get; set; }

		[Parameter(Position = 2)]
		public object Parameters { get; set; }

		protected override void BeginProcessing()
		{
			if (Filter == null)
			{
				foreach (var doc in Collection.FindAll())
					WriteObject(Actor.ToObject(doc));
			}
			else
			{
				var param = new InputParameters(Parameters);
				foreach (var doc in Collection.Find(param.Expression(Filter)))
					WriteObject(Actor.ToObject(doc));
			}
		}
	}
}
