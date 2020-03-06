
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using LiteDB;
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

		int _count = 0;

		System.Func<object, BsonDocument> _convert;

		protected override void BeginProcessing()
		{
			if (Add)
				_convert = Actor.ToBsonDocumentNoDefaultId(Collection.AutoId());
		}

		protected override void ProcessRecord()
		{
			if (InputObject == null)
				throw new PSArgumentException(Res.InputDocNull);

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
			if (Result)
				WriteObject(_count);
		}
	}
}
