
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
				return ToBsonDocumentFromProperties(null, custom, null, depth);

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
				return ToBsonDocumentFromDictionary(null, dictionary, null, depth);

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
		//! IConvertibleToBsonDocument (e.g. Mdbc.Dictionary) must be converted before if source and properties are null
		static BsonDocument ToBsonDocumentFromDictionary(BsonDocument source, IDictionary dictionary, IList<Selector> properties, int depth)
		{
			IncSerializationDepth(ref depth);

#if DEBUG
			if (source == null && properties == null && (dictionary is Dictionary || dictionary is BsonDocument))
				throw new InvalidOperationException("DEBUG: must be converted before.");
#endif

			// use source or new document
			var document = source ?? new BsonDocument();

			if (properties == null || properties.Count == 0)
			{
				foreach (DictionaryEntry de in dictionary)
				{
					if (de.Key is string name)
						document.Add(name, ToBsonValue(de.Value, depth));
					else
						throw new InvalidOperationException("Dictionary keys must be strings.");
				}
			}
			else
			{
				foreach (var selector in properties)
				{
					if (selector.PropertyName != null)
					{
						if (dictionary.Contains(selector.PropertyName))
							document.Add(selector.DocumentName, ToBsonValue(dictionary[selector.PropertyName], depth));
					}
					else
					{
						document.Add(selector.DocumentName, ToBsonValue(selector.GetValue(dictionary), depth));
					}
				}
			}

			return document;
		}
		// Input supposed to be not null
		static BsonDocument ToBsonDocumentFromProperties(BsonDocument source, PSObject value, IList<Selector> properties, int depth)
		{
			IncSerializationDepth(ref depth);

			var type = value.BaseObject.GetType();
			if (type.IsPrimitive || type == typeof(string))
				throw new InvalidOperationException(Res.CannotConvert2(type, nameof(BsonDocument)));

			// propertied omitted (null) of all (0)?
			if (properties == null || properties.Count == 0)
			{
				// if properties omitted (null) and the top (1) native object is not custom
				if (properties == null && depth == 1 && (!(value.BaseObject is PSCustomObject)))
				{
					try
					{
						return BsonMapper.Global.Serialize(type, value.BaseObject).AsDocument;
					}
					catch (SystemException exn)
					{
						throw new InvalidOperationException(Res.CannotConvert3(type, nameof(BsonDocument), exn.Message), exn);
					}
				}
				else
				{
					// convert all properties to the source or new document
					var document = source ?? new BsonDocument();
					foreach (var pi in value.Properties)
					{
						try
						{
							document.Add(pi.Name, ToBsonValue(pi.Value, depth));
						}
						catch (GetValueException) // .Value may throw, e.g. ExitCode in Process
						{
							document.Add(pi.Name, BsonValue.Null);
						}
						catch (SystemException exn)
						{
							if (depth == 1)
								throw new InvalidOperationException(Res.CannotConvert3(type, nameof(BsonDocument), exn.Message), exn);
							else
								throw;
						}
					}
					return document;
				}
			}
			else
			{
				// existing or new document
				var document = source ?? new BsonDocument();
				foreach (var selector in properties)
				{
					if (selector.PropertyName != null)
					{
						var pi = value.Properties[selector.PropertyName];
						if (pi != null)
						{
							try
							{
								document.Add(selector.DocumentName, ToBsonValue(pi.Value, depth));
							}
							catch (GetValueException) // .Value may throw, e.g. ExitCode in Process
							{
								document.Add(selector.DocumentName, BsonValue.Null);
							}
						}
					}
					else
					{
						document.Add(selector.DocumentName, ToBsonValue(selector.GetValue(value), depth));
					}
				}
				return document;
			}
		}
		//! For external use only.
		public static BsonDocument ToBsonDocument(object value)
		{
			return ToBsonDocument(null, value, null, 0);
		}
		//! For external use only.
		public static BsonDocument ToBsonDocument(BsonDocument source, object value, IList<Selector> properties)
		{
			return ToBsonDocument(source, value, properties, 0);
		}
		//! For external use only.
		internal static BsonDocument ToBsonDocumentFromDictionary(IDictionary value)
		{
			return ToBsonDocumentFromDictionary(null, value, null, 0);
		}
		static BsonDocument TryBsonDocument(object value)
		{
			if (value is Dictionary dic)
				return dic.ToBsonDocument();

			if (value is BsonDocument doc)
				return doc;

			return null;
		}
		static BsonDocument ToBsonDocument(BsonDocument source, object value, IList<Selector> properties, int depth)
		{
			value = BaseObject(value, out PSObject custom);

			// reuse existing document
			var document = TryBsonDocument(value);
			if (document != null)
			{
				// reuse
				if (source == null && properties == null)
					return document;

				// wrap, we need IDictionary, BsonDocument is not
				return ToBsonDocumentFromDictionary(source, new Dictionary(document), properties, depth);
			}

			if (value is IDictionary dictionary)
				return ToBsonDocumentFromDictionary(source, dictionary, properties, depth);

			return ToBsonDocumentFromProperties(source, custom ?? new PSObject(value), properties, depth);
		}
		static void IncSerializationDepth(ref int depth)
		{
			if (++depth > 20) //??
				throw new InvalidOperationException("Data exceed the default maximum serialization depth.");
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
		public static Func<object, BsonDocument> ToBsonDocumentNoDefaultId(BsonAutoId autoid)
		{
			return value =>
			{
				var doc = ToBsonDocument(value);
				RemoveDefaultId(doc, autoid);
				return doc;
			};
		}
	}
}
