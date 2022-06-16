
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using LiteDB;
using System.IO;
using System.Management.Automation;

namespace Ldbc.Commands
{
    [Cmdlet(VerbsCommon.New, "LiteDatabase", DefaultParameterSetName = NSConnectionString)]
    [OutputType(typeof(LiteDatabase))]
    public class NewDatabaseCommand : Abstract
    {
        protected const string NSConnectionString = "ConnectionString";
        const string NSStream = "Stream";
        const string NameMemoryDB = ":memory:";

        [Parameter(ParameterSetName = NSConnectionString, Position = 0)]
        [ValidateNotNull]
        public ConnectionString ConnectionString { get; set; }

        [Parameter(ParameterSetName = NSConnectionString)]
        public ConnectionType Connection { set { _Connection = value; } }
        ConnectionType? _Connection;

        [Parameter(ParameterSetName = NSConnectionString)]
        public SwitchParameter ReadOnly { set { _ReadOnly = value; } }
        bool? _ReadOnly;

        [Parameter(ParameterSetName = NSConnectionString)]
        public SwitchParameter Upgrade { set { _Upgrade = value; } }
        bool? _Upgrade;

        //! It used to be positional (0) and worked fine as such.
        // But on some -Missing X caused weird "cannot resolve".
        [Parameter(ParameterSetName = NSStream, Mandatory = true)]
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
                {
                    ConnectionString = new ConnectionString(NameMemoryDB);
                }
                else if (!ConnectionString.Filename.Equals(NameMemoryDB, System.StringComparison.OrdinalIgnoreCase))
                {
                    ConnectionString.Filename = GetUnresolvedProviderPathFromPSPath(ConnectionString.Filename);
                }

                if (_Connection.HasValue)
                    ConnectionString.Connection = _Connection.Value;

                if (_ReadOnly.HasValue)
                    ConnectionString.ReadOnly = _ReadOnly.Value;

                if (_Upgrade.HasValue)
                    ConnectionString.Upgrade = _Upgrade.Value;

                return new LiteDatabase(ConnectionString);
            }
        }

        protected override void BeginProcessing()
        {
            WriteObject(CreateDatabase());
        }
    }
}
