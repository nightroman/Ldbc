
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using LiteDB;
using System.Management.Automation;

namespace Ldbc.Commands
{
	[Cmdlet(VerbsCommon.Get, "LiteCollection")]
	[OutputType(typeof(ILiteCollection<BsonDocument>))]
	public sealed class GetCollectionCommand : Abstract
	{
		[Parameter(Position = 0, Mandatory = true)]
		public string CollectionName { get; set; }

		[Parameter(Position = 1)]
		public BsonAutoId AutoId { set { _AutoId = value; } }
		//! ensure default is ObjectId
		BsonAutoId _AutoId = BsonAutoId.ObjectId;

		[Parameter]
		public ILiteDatabase Database { get; set; }

		protected override void BeginProcessing()
		{
			if (Database == null)
				Database = ResolveDatabase();

			var collection = Database.GetCollection(CollectionName, _AutoId);
			WriteObject(collection);
		}
	}
}
