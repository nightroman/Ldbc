
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using LiteDB;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;

namespace Ldbc.Commands
{
	[Cmdlet(VerbsCommon.Set, "LiteData")]
	public sealed class SetDataCommand : Abstract
	{
		[Parameter(Position = 0, Mandatory = true)]
		public ILiteCollection<BsonDocument> Collection { get; set; }

		[Parameter(Position = 1, ValueFromPipeline = true)]
		public object InputObject { get; set; }

		[Parameter]
		public SwitchParameter Add { get; set; }

		[Parameter]
		public SwitchParameter Result { get; set; }

		[Parameter]
		public SwitchParameter Batch { get; set; }
		List<object> _batch;

		int _count = 0;

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
				if (Add)
				{
					if (Collection.Upsert(Actor.ToBsonDocument(InputObject)))
						++_count;
				}
				else
				{
					if (Collection.Update(Actor.ToBsonDocument(InputObject)))
						++_count;
				}
			}
			catch (LiteException exn)
			{
				WriteException(exn, InputObject);
			}
		}

		protected override void EndProcessing()
		{
			if (Batch)
			{
				if (Add)
					_count = Collection.Upsert(_batch.Select(Actor.ToBsonDocument));
				else
					_count = Collection.Update(_batch.Select(Actor.ToBsonDocument));
			}

			if (Result)
				WriteObject(_count);
		}
	}
}
