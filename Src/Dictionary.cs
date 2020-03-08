
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using LiteDB;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;

namespace Ldbc
{
	//! sync logic with Collection
	public sealed class Dictionary : IDictionary<string, object>, IDictionary
	{
		readonly BsonDocument _document;
		public static implicit operator BsonDocument(Dictionary value)
		{
			return value?._document;
		}
		public Dictionary()
		{
			_document = new BsonDocument();
		}
		/// <summary>
		/// Wrapper.
		/// </summary>
		public Dictionary(BsonDocument document)
		{
			_document = document ?? throw new ArgumentNullException(nameof(document));
		}
		/// <summary>
		/// Deep clone or convert dictionaries.
		/// </summary>
		[Obsolete("Designed for scripts.")]
		public Dictionary(IDictionary document)
		{
			if (document == null)
				throw new ArgumentNullException(nameof(document));

			_document = Actor.ToBsonDocumentFromDictionary(document);
		}
		public BsonDocument ToBsonDocument()
		{
			return _document;
		}
		public string Print()
		{
			return MyJson.Print(_document);
		}
		//! Do not use name Parse or PS converts all types to strings and produces not clear errors.
		//! This would be fine on .Parse(X), but PS calls Parse on `[Mdbc.Dictionary]X`, bad.
		//! And do not use constructor of string for the same reason.
		static public Dictionary FromJson(string json)
		{
			var bson = JsonSerializer.Deserialize(json);
			if (bson.Type == BsonType.Document)
				return new Dictionary(bson.AsDocument);
			else
				throw new ArgumentException($"Expected document, found {bson.Type}.");
		}
		public void EnsureId()
		{
			if (!_document.ContainsKey("_id"))
				_document.Add("_id", new BsonValue(ObjectId.NewObjectId()));
		}

		#region Object
		public override bool Equals(object obj)
		{
			return obj is Dictionary dic && _document.Equals(dic._document);
		}
		public override int GetHashCode()
		{
			return _document.GetHashCode();
		}
		public override string ToString()
		{
			return _document.ToString();
		}
		#endregion

		#region Common
		public int Count => _document.Count;
		public bool IsReadOnly => _document.IsReadOnly;
		public void Clear()
		{
			_document.Clear();
		}
		#endregion

		#region ICollection
		bool ICollection.IsSynchronized => false;
		object ICollection.SyncRoot => null;
		void ICollection.CopyTo(Array array, int index)
		{
			throw new NotImplementedException();
		}
		#endregion

		#region ICollection2
		void ICollection<KeyValuePair<string, object>>.Add(KeyValuePair<string, object> item)
		{
			_document.Add(item.Key, Actor.ToBsonValue(item.Value));
		}
		bool ICollection<KeyValuePair<string, object>>.Contains(KeyValuePair<string, object> item)
		{
			return _document.ContainsKey(item.Key);
		}
		void ICollection<KeyValuePair<string, object>>.CopyTo(KeyValuePair<string, object>[] array, int index)
		{
			throw new NotImplementedException();
		}
		bool ICollection<KeyValuePair<string, object>>.Remove(KeyValuePair<string, object> item)
		{
			return _document.Remove(item.Key);
		}
		public IEnumerator<KeyValuePair<string, object>> GetEnumerator()
		{
			return new DocumentEnumerator2(_document.GetEnumerator());
		}
		class DocumentEnumerator2 : IEnumerator<KeyValuePair<string, object>>
		{
			readonly IEnumerator<KeyValuePair<string, BsonValue>> _that;
			public DocumentEnumerator2(IEnumerator<KeyValuePair<string, BsonValue>> that)
			{
				_that = that;
			}
			void IDisposable.Dispose() { }
			public KeyValuePair<string, object> Current => new KeyValuePair<string, object>(_that.Current.Key, Actor.ToObject(_that.Current.Value));
			object IEnumerator.Current => Current;
			public bool MoveNext() { return _that.MoveNext(); }
			public void Reset() { _that.Reset(); }
		}
		#endregion

		#region IDictionary
		bool IDictionary.IsFixedSize => _document.IsReadOnly;
		ICollection IDictionary.Keys => _document.Keys.ToArray();
		ICollection IDictionary.Values => _document.Values.Select(Actor.ToObject).ToArray();
		object IDictionary.this[object key]
		{
			get
			{
				if (key == null) throw new ArgumentNullException(nameof(key));
				return _document.TryGetValue(key.ToString(), out BsonValue value) ? Actor.ToObject(value) : null;
			}
			set
			{
				if (key == null) throw new ArgumentNullException(nameof(key));
				_document[key.ToString()] = Actor.ToBsonValue(value);
			}
		}
		public void Remove(object key)
		{
			if (key == null) throw new ArgumentNullException(nameof(key));
			_document.Remove(key.ToString());
		}
		void IDictionary.Add(object key, object value)
		{
			if (key == null) throw new ArgumentNullException(nameof(key));
			_document.Add(key.ToString(), Actor.ToBsonValue(value));
		}
		public bool Contains(object key)
		{
			if (key == null) throw new ArgumentNullException(nameof(key));
			return _document.ContainsKey(key.ToString());
		}
		IDictionaryEnumerator IDictionary.GetEnumerator()
		{
			return new DocumentEnumerator(_document.GetEnumerator());
		}
		IEnumerator IEnumerable.GetEnumerator()
		{
			return new DocumentEnumerator(_document.GetEnumerator());
		}
		class DocumentEnumerator : IDictionaryEnumerator
		{
			readonly IEnumerator<KeyValuePair<string, BsonValue>> _that;
			public DocumentEnumerator(IEnumerator<KeyValuePair<string, BsonValue>> that)
			{
				_that = that;
			}
			public DictionaryEntry Entry => new DictionaryEntry(_that.Current.Key, Actor.ToObject(_that.Current.Value));
			public object Key => _that.Current.Key;
			public object Value => Actor.ToObject(_that.Current.Value);
			public object Current => Entry;
			public void Reset() { _that.Reset(); }
			public bool MoveNext() { return _that.MoveNext(); }
		}
		#endregion

		#region IDictionary2
		public ICollection<string> Keys => _document.Keys.ToArray();
		public ICollection<object> Values => _document.Values.Select(Actor.ToObject).ToArray();
		public object this[string key]
		{
			get
			{
				if (key == null) throw new ArgumentNullException(nameof(key));
				return _document.TryGetValue(key, out BsonValue value) ? Actor.ToObject(value) : null;
			}
			set
			{
				if (key == null) throw new ArgumentNullException(nameof(key));
				_document[key] = Actor.ToBsonValue(value);
			}
		}
		public void Add(string key, object value)
		{
			if (key == null) throw new ArgumentNullException(nameof(key));
			_document.Add(key, Actor.ToBsonValue(value));
		}
		public bool TryGetValue(string key, out object value)
		{
			if (_document.TryGetValue(key, out BsonValue value2))
			{
				value = Actor.ToObject(value2);
				return true;
			}
			else
			{
				value = null;
				return false;
			}
		}
		public bool ContainsKey(string key)
		{
			return _document.ContainsKey(key);
		}
		//! private, do not want in PowerShell for returned bool
		bool IDictionary<string, object>.Remove(string key)
		{
			return _document.Remove(key);
		}
		#endregion
	}
}
