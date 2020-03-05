
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using LiteDB;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Reflection;

namespace Ldbc.Commands
{
	static class CollectionExt //rk temp
	{
		static readonly FieldInfo _autoiId = typeof(LiteCollection<BsonDocument>).GetField("_autoId", BindingFlags.Instance | BindingFlags.NonPublic);
		public static BsonAutoId AutoId(this ILiteCollection<BsonDocument> collection)
		{
			return (BsonAutoId)_autoiId.GetValue(collection);
		}
	}

	[Cmdlet(VerbsCommon.Add, "LiteData")]
	public sealed class AddDataCommand : Abstract
	{
		[Parameter(Position = 0, Mandatory = true)]
		public ILiteCollection<BsonDocument> Collection { get; set; }

		[Parameter(Position = 1, ValueFromPipeline = true)]
		public object InputObject { get; set; }

		[Parameter]
		public SwitchParameter Result { get; set; }

		[Parameter]
		public SwitchParameter Bulk { get; set; }
		List<object> _bulk;

		BsonAutoId _autoId; //rk temp

		protected override void BeginProcessing()
		{
			_autoId = Collection.AutoId();
			if (Bulk)
				_bulk = new List<object>();
		}

		protected override void ProcessRecord()
		{
			if (InputObject == null)
				throw new PSArgumentException(Res.InputDocNull);

			if (Bulk)
			{
				_bulk.Add(InputObject);
				return;
			}

			try
			{
				var document = Actor.ToBsonDocument(InputObject);
				Actor.RemoveDefaultId(document, _autoId);
				var id = Collection.Insert(document);
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

		protected override void EndProcessing()
		{
			if (!Bulk)
				return;

			var convert = Actor.ToBsonDocumentNoDefaultId(_autoId);
			var count = Collection.Insert(_bulk.Select(convert));
			if (Result)
				WriteObject(count);
		}
	}
}
