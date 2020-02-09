
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using LiteDB;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;

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
		public SwitchParameter Batch { get; set; }
		List<object> _batch;

		protected override void BeginProcessing()
		{
			if (Batch)
				_batch = new List<object>();
		}

		protected override void ProcessRecord()
		{
			if (InputObject == null)
				throw new PSArgumentException(Res.InputDocNull);

			if (Batch)
			{
				_batch.Add(InputObject);
				return;
			}

			try
			{
				var document = Actor.ToBsonDocument(InputObject);
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
			if (!Batch)
				return;

			var count = Collection.Insert(_batch.Select(Actor.ToBsonDocument));
			if (Result)
				WriteObject(count);
		}
	}
}
