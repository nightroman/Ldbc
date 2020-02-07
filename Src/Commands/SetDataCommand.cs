
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

		//! `get` is needed for PS, check null later =1=
		[Parameter(Position = 1, ValueFromPipeline = true)]
		public object InputObject { get { return _InputObject; } set { if (value != null) _InputObject = Actor.ToBsonDocument(value); } }
		BsonDocument _InputObject;

		[Parameter]
		public SwitchParameter Add { get; set; }

		[Parameter]
		public SwitchParameter Result { get; set; }

		int _count = 0;

		protected override void ProcessRecord()
		{
			if (_InputObject == null) //=1=
				throw new PSArgumentException(Res.InputDocNull);

			try
			{
				if (Add)
				{
					if (Collection.Upsert(_InputObject))
						++_count;
				}
				else
				{
					if (Collection.Update(_InputObject))
						++_count;
				}
			}
			catch (LiteException exn)
			{
				WriteException(exn, _InputObject);
			}
		}

		protected override void EndProcessing()
		{
			if (Result)
				WriteObject(_count);
		}
	}
}
