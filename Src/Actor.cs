
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using LiteDB;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Management.Automation;

namespace Ldbc
{
	static class Actor
	{
		public const string DatabaseVariable = "Database";
		/// <summary>
		/// null | PSObject.BaseObject | self
		/// </summary>
		public static object BaseObject(object value)
		{
			return value == null ? null : value is PSObject ps ? ps.BaseObject : value;
		}
		/// <summary>
		/// null | PSCustomObject | PSObject.BaseObject | self
		/// </summary>
		public static object BaseObject(object value, out PSObject custom)
		{
			custom = null;

			if (value == null)
				return null;

			if (!(value is PSObject ps))
				return value;

			if (!(ps.BaseObject is PSCustomObject))
				return ps.BaseObject;

			custom = ps;
			return ps;
		}
		public static object ToObject(BsonValue value)
		{
			if (value == null)
				return null;

			switch (value.Type)
			{
				case BsonType.Array: return new Collection((BsonArray)value); // wrapper
				case BsonType.Binary: return value.AsBinary;
				case BsonType.Boolean: return value.AsBoolean;
				case BsonType.DateTime: return value.AsDateTime;
				case BsonType.Decimal: return value.AsDecimal;
				case BsonType.Document: return new Dictionary((BsonDocument)value); // wrapper
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
		//! For external use only.
		public static BsonValue ToBsonValue(object value)
		{
			return ToBsonValue(value, 0);
		}
		static BsonValue ToBsonValue(object value, int depth)
		{
			IncSerializationDepth(ref depth);

			if (value == null)
				return BsonValue.Null;

			value = BaseObject(value, out PSObject custom);

			// case: custom
			if (custom != null)
				return ToBsonDocumentFromCustom(custom, depth);

			// case: BsonValue
			if (value is BsonValue bson)
				return bson;

			// case: string
			if (value is string text)
				return new BsonValue(text);

			// case: document
			var document = TryBsonDocument(value);
			if (document != null)
				return document;

			// case: dictionary
			if (value is IDictionary dictionary)
				return ToBsonDocumentFromDictionary(dictionary, depth);

			// case: bytes or collection
			if (value is IEnumerable en)
			{
				if (en is byte[] bytes)
					return new BsonValue(bytes);

				var array = new BsonArray();
				foreach (var it in en)
					array.Add(ToBsonValue(it, depth));
				return array;
			}

			// serialize value
			return BsonMapper.Global.Serialize(value.GetType(), value);
		}
		//! Normally BsonDocument should be converted before.
		//! But: // (a) properties; (b) Dictionary(Dictionary|BsonDocument).
		static BsonDocument ToBsonDocumentFromDictionary(IDictionary dictionary, int depth)
		{
			IncSerializationDepth(ref depth);

			var document = new BsonDocument();
			foreach (DictionaryEntry de in dictionary)
			{
				if (de.Key is string name)
					document.Add(name, ToBsonValue(de.Value, depth));
				else
					throw new InvalidOperationException("Dictionary keys must be strings.");
			}

			return document;
		}
		// Input is not null and not PSObject
		static BsonDocument ToBsonDocumentFromComplex(object value, int depth)
		{
			IncSerializationDepth(ref depth);

			var type = value.GetType();
			if (type.IsPrimitive || type == typeof(string))
				throw new InvalidOperationException(Res.CannotConvert2(type, nameof(BsonDocument)));

			try
			{
				return BsonMapper.Global.Serialize(type, value).AsDocument;
			}
			catch (Exception exn)
			{
				throw new InvalidOperationException(Res.CannotConvert3(type, nameof(BsonDocument), exn.Message), exn);
			}
		}
		// Input is not null
		static BsonDocument ToBsonDocumentFromCustom(PSObject value, int depth)
		{
			IncSerializationDepth(ref depth);
			try
			{
				var document = new BsonDocument();
				foreach (var pi in value.Properties)
					document.Add(pi.Name, ToBsonValue(pi.Value, depth));
				return document;
			}
			catch (Exception exn)
			{
				throw new InvalidOperationException(Res.CannotConvert3(value.BaseObject.GetType(), nameof(BsonDocument), exn.Message), exn);
			}
		}
		//! For external use only.
		public static BsonDocument ToBsonDocument(object value)
		{
			return ToBsonDocument(value, 0);
		}
		//! For external use only.
		internal static BsonDocument ToBsonDocumentFromDictionary(IDictionary value)
		{
			return ToBsonDocumentFromDictionary(value, 0);
		}
		static BsonDocument TryBsonDocument(object value)
		{
			if (value is Dictionary dic)
				return dic.ToBsonDocument();

			if (value is BsonDocument doc)
				return doc;

			return null;
		}
		static BsonDocument ToBsonDocument(object value, int depth)
		{
			value = BaseObject(value, out PSObject custom);

			// custom
			if (custom != null)
				return ToBsonDocumentFromCustom(custom, depth);

			// document
			var document = TryBsonDocument(value);
			if (document != null)
				return document;

			// dictionary
			if (value is IDictionary dictionary)
				return ToBsonDocumentFromDictionary(dictionary, depth);

			// complex
			return ToBsonDocumentFromComplex(value, depth);
		}
		static void IncSerializationDepth(ref int depth)
		{
			if (++depth > BsonMapper.Global.MaxDepth)
				throw new InvalidOperationException($"Data exceed the maximum depth {BsonMapper.Global.MaxDepth}.");
		}
		public static Collection<PSObject> InvokeScript(ScriptBlock script, object value)
		{
			var vars = new List<PSVariable>() { new PSVariable("_", value) };
			return script.InvokeWithContext(null, vars);
		}
		//_200223_064239
		public static void RemoveDefaultId(BsonDocument doc, BsonAutoId autoId)
		{
			if (doc.TryGetValue("_id", out var id))
			{
				if (id.IsNull
					|| autoId == BsonAutoId.Int32 && id.IsInt32 && id.AsInt32 == 0
					|| autoId == BsonAutoId.ObjectId && id.IsObjectId && id.AsObjectId == ObjectId.Empty
					|| autoId == BsonAutoId.Guid && id.IsGuid && id.AsGuid == Guid.Empty
					|| autoId == BsonAutoId.Int64 && id.IsInt64 && id.AsInt64 == 0L)
				{
					doc.Remove("_id");
				}
			}
		}
		//_200223_064239
		public static Func<object, BsonDocument> ToBsonDocumentNoDefaultId(BsonAutoId autoId)
		{
			return value =>
			{
				var doc = ToBsonDocument(value);
				RemoveDefaultId(doc, autoId);
				return doc;
			};
		}
	}
}
