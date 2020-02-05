
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using LiteDB;
using System.IO;
using System.Management.Automation;

namespace Ldbc.Commands
{
	[Cmdlet(VerbsCommon.New, "LiteDatabase", DefaultParameterSetName = nsConnectionString)]
	[OutputType(typeof(LiteDatabase))]
	public class NewDatabaseCommand : Abstract
	{
		protected const string nsConnectionString = "ConnectionString";
		const string nsStream = "Stream";

		[Parameter(Position = 0, ParameterSetName = nsConnectionString)]
		[ValidateNotNull]
		public ConnectionString ConnectionString { get; set; }

		[Parameter(Position = 0, ParameterSetName = nsStream)]
		[ValidateNotNull]
		public Stream Stream { get; set; }

		protected LiteDatabase CreateDatabase()
		{
			if (Stream != null)
			{
				return new LiteDatabase(Stream);
			}
			else
			{
				if (ConnectionString == null)
					ConnectionString = new ConnectionString(":memory:");

				return new LiteDatabase(ConnectionString);
			}
		}

		protected override void BeginProcessing()
		{
			WriteObject(CreateDatabase());
		}
	}
}
