
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
			return ToBsonValue(value, null, 0);
		}
		static BsonValue ToBsonValue(object value, ScriptBlock convert, int depth)
		{
			IncSerializationDepth(ref depth);

			if (value == null)
				return BsonValue.Null;

			value = BaseObject(value, out PSObject custom);

			// case: custom
			if (custom != null)
				return ToBsonDocumentFromProperties(null, custom, convert, null, depth);

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
				return ToBsonDocumentFromDictionary(null, dictionary, convert, null, depth);

			// case: bytes or collection
			if (value is IEnumerable en)
			{
				if (en is byte[] bytes)
					return new BsonValue(bytes);

				var array = new BsonArray();
				foreach (var it in en)
					array.Add(ToBsonValue(it, convert, depth));
				return array;
			}

			// try to map BsonValue //??
			if (BsonTypeMapper.TryMapToBsonValue(value, out BsonValue bson2))
				return bson2;

			// try to serialize class //??
			var type = value.GetType();
			if (TypeIsDriverSerialized(type))
				//return BsonExtensionMethods.ToBsonDocument(value, type);
				throw new NotImplementedException();

			// no converter? //??
			if (convert == null)
				return BsonMapper.Global.Serialize(type, value);

			try
			{
				value = DocumentInput.ConvertValue(convert, value);
			}
			catch (RuntimeException re)
			{
				//! use this type
				throw new ArgumentException($"Converter script was called for '{type}' and failed with '{re.Message}'.", re);
			}

			// do not pass converter twice
			return ToBsonValue(value, null, depth);
		}
		//! IConvertibleToBsonDocument (e.g. Mdbc.Dictionary) must be converted before if source and properties are null
		static BsonDocument ToBsonDocumentFromDictionary(BsonDocument source, IDictionary dictionary, ScriptBlock convert, IList<Selector> properties, int depth)
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
						document.Add(name, ToBsonValue(de.Value, convert, depth));
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
							document.Add(selector.DocumentName, ToBsonValue(dictionary[selector.PropertyName], convert, depth));
					}
					else
					{
						document.Add(selector.DocumentName, ToBsonValue(selector.GetValue(dictionary), convert, depth));
					}
				}
			}

			return document;
		}
		internal static bool TypeIsDriverSerialized(Type type)
		{
			//return ClassMap.Contains(type); //??
			System.Diagnostics.Debug.WriteLine(type);
			return false;
		}
		// Input supposed to be not null
		static BsonDocument ToBsonDocumentFromProperties(BsonDocument source, PSObject value, ScriptBlock convert, IList<Selector> properties, int depth)
		{
			IncSerializationDepth(ref depth);

			var type = value.BaseObject.GetType();
			if (type.IsPrimitive || type == typeof(string))
				throw new InvalidOperationException(Res.CannotConvert2(type, nameof(BsonDocument)));

			// propertied omitted (null) of all (0)?
			if (properties == null || properties.Count == 0)
			{
				// if properties omitted (null) and the top (1) native object is not custom
				if (properties == null && depth == 1 && (!(value.BaseObject is PSCustomObject)) && TypeIsDriverSerialized(type))
				{
					try
					{
						throw new NotImplementedException();
						//// serialize the top level native object //??
						//var document = BsonExtensionMethods.ToBsonDocument(value.BaseObject, type);

						//// return the result
						//if (source == null)
						//	return document;

						//// add to the provided document
						//source.AddRange(document.Elements);
						//return source;
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
							document.Add(pi.Name, ToBsonValue(pi.Value, convert, depth));
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
								document.Add(selector.DocumentName, ToBsonValue(pi.Value, convert, depth));
							}
							catch (GetValueException) // .Value may throw, e.g. ExitCode in Process
							{
								document.Add(selector.DocumentName, BsonValue.Null);
							}
						}
					}
					else
					{
						document.Add(selector.DocumentName, ToBsonValue(selector.GetValue(value), convert, depth));
					}
				}
				return document;
			}
		}
		//! For external use only.
		public static BsonDocument ToBsonDocument(object value)
		{
			return ToBsonDocument(null, value, null, null, 0);
		}
		//! For external use only.
		public static BsonDocument ToBsonDocument(BsonDocument source, object value, ScriptBlock convert, IList<Selector> properties)
		{
			return ToBsonDocument(source, value, convert, properties, 0);
		}
		//! For external use only.
		internal static BsonDocument ToBsonDocumentFromDictionary(IDictionary value)
		{
			return ToBsonDocumentFromDictionary(null, value, null, null, 0);
		}
		static BsonDocument TryBsonDocument(object value)
		{
			if (value is Dictionary dic)
				return dic.ToBsonDocument();

			if (value is BsonDocument doc)
				return doc;

			return null;
		}
		static BsonDocument ToBsonDocument(BsonDocument source, object value, ScriptBlock convert, IList<Selector> properties, int depth)
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
				return ToBsonDocumentFromDictionary(source, new Dictionary(document), convert, properties, depth);
			}

			if (value is IDictionary dictionary)
				return ToBsonDocumentFromDictionary(source, dictionary, convert, properties, depth);

			return ToBsonDocumentFromProperties(source, custom ?? new PSObject(value), convert, properties, depth);
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
	}
}
