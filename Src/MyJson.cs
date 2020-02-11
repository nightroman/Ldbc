
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using LiteDB;
using System;
using System.IO;

namespace Ldbc
{
	class DocumentPrinter : IDisposable
	{
		readonly StringWriter _writer = new StringWriter();
		string _indent = "";

		public static string Print(BsonDocument document)
		{
			using (var writer = new DocumentPrinter())
			{
				writer.PrintDocument(document);
				return writer._writer.ToString();
			}
		}
		public void Dispose()
		{
			_writer.Dispose();
		}
		void IncIndent()
		{
			_indent += "  ";
		}
		void DecIndent()
		{
			_indent = _indent.Substring(0, _indent.Length - 2);
		}
		void PrintArray(BsonArray array)
		{
			if (array.Count == 0)
			{
				_writer.Write("[]");
				return;
			}

			_writer.WriteLine("[");
			IncIndent();
			for (int i = 0; i < array.Count; ++i)
			{
				_writer.Write(_indent);
				var value = array[i];
				switch (value.Type)
				{
					case BsonType.Array:
						PrintArray(value.AsArray);
						break;
					case BsonType.Document:
						PrintDocument(value.AsDocument);
						break;
					default:
						_writer.Write(value.ToString());
						break;
				}
				if (i < array.Count - 1)
					_writer.WriteLine(",");
				else
					_writer.WriteLine();
			}
			DecIndent();
			_writer.Write($"{_indent}]");
		}
		void PrintDocument(BsonDocument document)
		{
			if (document.Count == 0)
			{
				_writer.Write("{}");
				return;
			}

			_writer.WriteLine("{");
			IncIndent();
			int i = 0;
			foreach (var kv in document)
			{
				_writer.Write($"{_indent}\"{kv.Key}\" : ");
				switch (kv.Value.Type)
				{
					case BsonType.Array:
						PrintArray(kv.Value.AsArray);
						break;
					case BsonType.Document:
						PrintDocument(kv.Value.AsDocument);
						break;
					default:
						_writer.Write(kv.Value.ToString());
						break;
				}
				if (++i < document.Count)
					_writer.WriteLine(",");
				else
					_writer.WriteLine();
			}
			DecIndent();
			_writer.Write($"{_indent}}}");
		}
	}
}
