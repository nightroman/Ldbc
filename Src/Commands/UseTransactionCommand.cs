
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using LiteDB;
using System.Management.Automation;

namespace Ldbc.Commands
{
	[Cmdlet(VerbsOther.Use, "LiteTransaction")]
	public sealed class UseTransactionCommand : Abstract
	{
		[Parameter(Position = 0, Mandatory = true)]
		public ScriptBlock Script { get; set; }

		[Parameter]
		public ILiteDatabase Database { get; set; }

		protected override void BeginProcessing()
		{
			if (Database == null)
				Database = ResolveDatabase();

			var trans = Database.BeginTrans();
			try
			{
				try
				{
					var result = Script.Invoke();
					foreach (var item in result)
						WriteObject(item);
				}
				catch (RuntimeException exn)
				{
					ThrowWithPositionMessage(exn);
				}

				if (trans)
					Database.Commit();
			}
			catch
			{
				if (trans)
					Database.Rollback();

				throw;
			}
		}
	}
}
