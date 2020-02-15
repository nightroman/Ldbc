
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using LiteDB;
using System;
using System.Linq;
using System.Management.Automation;

namespace Ldbc.Commands
{
	[Cmdlet(VerbsLifecycle.Register, "LiteType")]
	public sealed class RegisterClassMapCommand : Abstract
	{
		[Parameter(Position = 0, Mandatory = true)]
		public Type Type { get; set; }

		[Parameter(Position = 1)]
		public ScriptBlock Serialize { get; set; }

		[Parameter(Position = 2)]
		public ScriptBlock Deserialize { get; set; }

		static BsonValue DoSerialize(ScriptBlock script, object value)
		{
			if (script == null)
				return null;

			var r = Actor.InvokeScript(script, value);

			if (r.Count == 0)
				return null;

			if (r.Count == 1)
				return Actor.ToBsonValue(r[0]);

			var array = new BsonArray(r.Select(Actor.ToBsonValue));
			return array;
		}

		static object DoDeserialize(ScriptBlock script, BsonValue value)
		{
			if (script == null)
				return null;

			var r = Actor.InvokeScript(script, Actor.ToObject(value));
			if (r.Count == 0)
				return null;

			if (r.Count > 1)
				throw new ArgumentException($"Deserialize: expected one or no object, returned {r.Count} objects.");

			return Actor.BaseObject(r[0], out _);
		}

		protected override void BeginProcessing()
		{
			BsonMapper.Global.RegisterType(Type, x => DoSerialize(Serialize, x), x => DoDeserialize(Deserialize, x));
		}
	}
}
