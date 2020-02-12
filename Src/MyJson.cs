
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using LiteDB;
using System.IO;

namespace Ldbc
{
	static class MyJson
	{
		internal static string Print(BsonValue value)
		{
			var stringWriter = new StringWriter();
			var jsonWriter = new JsonWriter(stringWriter) { Pretty = true, Indent = 2 };
			jsonWriter.Serialize(value);
			return stringWriter.ToString();
		}
	}
}
