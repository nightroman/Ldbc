
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using LiteDB;
using System;
using System.Collections;

namespace Ldbc
{
	static class BsonTypeMapper
	{
		public static bool TryMapToBsonValue(object value, out BsonValue bson)
		{
			if (value == null)
			{
				bson = BsonValue.Null;
			}
			else if (value is int int32)
			{
				bson = new BsonValue(int32);
			}
			else if (value is long int64)
			{
				bson = new BsonValue(int64);
			}
			else if (value is double d1)
			{
				bson = new BsonValue(d1);
			}
			else if (value is decimal d2)
			{
				bson = new BsonValue(d2);
			}
			else if (value is string text)
			{
				bson = new BsonValue(text);
			}
			else if (value is byte[] bytes)
			{
				bson = new BsonValue(bytes);
			}
			else if (value is ObjectId id)
			{
				bson = new BsonValue(id);
			}
			else if (value is Guid guid)
			{
				bson = new BsonValue(guid);
			}
			else if (value is bool b)
			{
				bson = new BsonValue(b);
			}
			else if (value is DateTime date)
			{
				bson = new BsonValue(date);
			}
			else if (value is BsonValue bson2)
			{
				bson = bson2;
			}
			else if (value is IDictionary dic) //?? fail?
			{
				var doc = new BsonDocument();
				foreach(DictionaryEntry kv in dic)
				{
					if (TryMapToBsonValue(kv.Value, out BsonValue value2))
						doc.Add(kv.Key.ToString(), value2);
					else
						Res.CannotConvert2(kv.Value, typeof(BsonValue));
				}
				bson = doc;
			}
			else if (value is IEnumerable list) //?? fail?
			{
				var arr = new BsonArray();
				foreach (var item in list)
				{
					if (TryMapToBsonValue(item, out BsonValue value2))
						arr.Add(value2);
					else
						Res.CannotConvert2(item, typeof(BsonValue));
				}
				bson = arr;
			}
			else
			{
				bson = null;
				return false;
			}
			return true;
		}
	}
}
