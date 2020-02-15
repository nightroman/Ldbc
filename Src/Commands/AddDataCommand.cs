
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

		static MethodInfo _RemoveDocId; //rk work around

		protected override void BeginProcessing()
		{
			if (Bulk)
				_bulk = new List<object>();
			else
				_RemoveDocId = typeof(LiteCollection<BsonDocument>).GetMethod("RemoveDocId", BindingFlags.NonPublic | BindingFlags.Instance, null, new Type[] { typeof(BsonDocument) }, null);
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
				//rk work around
				_RemoveDocId.Invoke(Collection, new object[] { document });
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

			var count = Collection.Insert(_bulk.Select(Actor.ToBsonDocument));
			if (Result)
				WriteObject(count);
		}
	}
}
