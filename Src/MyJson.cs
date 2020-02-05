
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using Newtonsoft.Json;
using System.IO;

namespace Ldbc
{
	static class MyJson
	{
		internal static string Format(string json)
		{
			using (var stringReader = new StringReader(json))
			using (var stringWriter = new StringWriter())
			{
				using (var jsonReader = new JsonTextReader(stringReader))
				using (var jsonWriter = new JsonTextWriter(stringWriter) { Formatting = Formatting.Indented })
				{
					jsonWriter.WriteToken(jsonReader);
					return stringWriter.ToString();
				}
			}
		}
	}
}
