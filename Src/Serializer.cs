
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using LiteDB;
using System.Collections;
using System.Collections.Generic;
using System.Management.Automation;

namespace Ldbc
{
	static class PSObjectSeializer
	{
		static object ReadObject(BsonValue value)
		{
			switch (value.Type)
			{
				case BsonType.Array: return ReadArray(value.AsArray); // replacement
				case BsonType.Binary: return value.AsBinary;
				case BsonType.Boolean: return value.AsBoolean;
				case BsonType.DateTime: return value.AsDateTime;
				case BsonType.Decimal: return value.AsDecimal;
				case BsonType.Document: return ReadCustomObject(value.AsDocument); // replacement
				case BsonType.Double: return value.AsDouble;
				case BsonType.Guid: return value.AsGuid;
				case BsonType.Int32: return value.AsInt32;
				case BsonType.Int64: return value.AsInt64;
				case BsonType.Null: return null;
				case BsonType.ObjectId: return value.AsObjectId;
				case BsonType.String: return value.AsString;
				default: return value;
			}
		}
		static IList ReadArray(BsonArray value)
		{
			var list = new List<object>(value.Count);
			for (int i = 0; i < value.Count; ++i)
				list.Add(ReadObject(value[i]));
			return list;
		}
		internal static PSObject ReadCustomObject(BsonDocument value)
		{
			var ps = new PSObject();
			var properties = ps.Properties;

			foreach (var kv in value)
			{
				var value2 = ReadObject(kv.Value);
				properties.Add(new PSNoteProperty(kv.Key, value2), true); //! true is faster
			}

			return ps;
		}
	}
}
