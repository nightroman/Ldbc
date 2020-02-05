
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using LiteDB;
using System;
using System.Management.Automation;

namespace Ldbc
{
	static class DocumentInput
	{
		public static object ConvertValue(ScriptBlock convert, object value)
		{
			var result = Actor.InvokeScript(convert, value);
			switch (result.Count)
			{
				case 0:
					return null;
				case 1:
					{
						var ps = result[0];
						return ps?.BaseObject;
					}
				default:
					//! use this type
					throw new RuntimeException($"Converter script should return one value or none but it returns {result.Count}.");
			}
		}
		public static BsonDocument NewDocumentWithId(bool newId, PSObject id, PSObject input)
		{
			if (newId && id != null)
				throw new PSInvalidOperationException("Parameters Id and NewId cannot be used together.");

			if (newId)
				return new BsonDocument() { ["_id"] = new BsonValue(ObjectId.NewObjectId()) };

			if (id == null)
				return null;

			if (!(id.BaseObject is ScriptBlock sb))
				return new BsonDocument() { ["_id"] = Actor.ToBsonValue(id.BaseObject) };

			var arr = Actor.InvokeScript(sb, input);
			if (arr.Count != 1)
				throw new ArgumentException("-Id script must return a single object."); //! use this type

			return new BsonDocument() { ["_id"] = Actor.ToBsonValue(arr[0].BaseObject) };
		}
		public static ErrorRecord NewErrorRecordBsonValue(Exception value, object targetObject)
		{
			return new ErrorRecord(value, "BsonValue", ErrorCategory.InvalidData, targetObject);
		}
	}
}
