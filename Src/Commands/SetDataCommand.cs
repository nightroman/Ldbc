
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
		public SwitchParameter Bulk { get; set; }
		List<object> _bulk;

		int _count = 0;

		System.Func<object, BsonDocument> _convert; //rk temp

		protected override void BeginProcessing()
		{
			if (Add)
				_convert = Actor.ToBsonDocumentNoDefaultId(Collection.AutoId());

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
				if (Add)
				{
					if (Collection.Upsert(_convert(InputObject)))
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
			if (Bulk)
			{
				if (Add)
					_count = Collection.Upsert(_bulk.Select(Actor.ToBsonDocument));
				else
					_count = Collection.Update(_bulk.Select(Actor.ToBsonDocument));
			}

			if (Result)
				WriteObject(_count);
		}
	}
}
