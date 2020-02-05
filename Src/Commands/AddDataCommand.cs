
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using LiteDB;
using System;
using System.Management.Automation;

namespace Ldbc.Commands
{
	[Cmdlet(VerbsCommon.Add, "LiteData")]
	public sealed class AddDataCommand : Abstract
	{
		[Parameter(Position = 0, Mandatory = true)]
		public string CollectionName { get; set; }

		[Parameter(Position = 1, ValueFromPipeline = true)]
		public object InputObject { get; set; }

		[Parameter]
		public ILiteDatabase Database { get; set; }

		[Parameter]
		public BsonAutoId AutoId { get { return _AutoId; } set { _AutoId = value; } }
		BsonAutoId _AutoId = BsonAutoId.ObjectId;

		[Parameter]
		public SwitchParameter Result { get; set; }

		ILiteCollection<BsonDocument> _collection;

		protected override void BeginProcessing()
		{
			if (Database == null)
				Database = ResolveDatabase();

			_collection = Database.GetCollection(CollectionName, _AutoId);
		}

		protected override void ProcessRecord()
		{
			if (InputObject == null)
			{
				if (Result)
					WriteObject(null);
				return;
			}

			try
			{
				var document = Actor.ToBsonDocument(InputObject);
				var id = _collection.Insert(document);
				if (Result)
					WriteObject(Actor.ToObject(id));
			}
			catch (ArgumentException exn)
			{
				WriteError(DocumentInput.NewErrorRecordBsonValue(exn, InputObject));
			}
			catch (LiteException exn)
			{
				WriteException(exn, InputObject);
			}
		}
	}
}
