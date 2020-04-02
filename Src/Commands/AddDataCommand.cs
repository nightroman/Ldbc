
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
		public ILiteCollection<BsonDocument> Collection { get; set; }

		[Parameter(Position = 1, ValueFromPipeline = true)]
		public object InputObject { get; set; }

		[Parameter]
		public SwitchParameter Result { get; set; }

		Func<object, BsonDocument> _convert;

		protected override void BeginProcessing()
		{
			_convert = Actor.ToBsonDocumentNoDefaultId(Collection.AutoId);
		}

		protected override void ProcessRecord()
		{
			if (InputObject == null)
				throw new PSArgumentException(Res.InputDocNull);

			try
			{
				var document = _convert(InputObject);
				var id = Collection.Insert(document);
				if (Result)
					WriteObject(Actor.ToObject(id));
			}
			catch (ArgumentException exn)
			{
				WriteErrorBsonValue(exn, InputObject);
			}
			catch (LiteException exn)
			{
				WriteErrorException(exn, InputObject);
			}
		}
	}
}
