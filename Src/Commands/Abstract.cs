
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using LiteDB;
using System;
using System.Collections;
using System.Management.Automation;

namespace Ldbc.Commands
{
	/// <summary>
	/// Common base class for commands.
	/// </summary>
	public abstract class Abstract : PSCmdlet
	{
		static protected void ThrowWithPositionMessage(RuntimeException exn)
		{
			if (exn == null) throw new InvalidOperationException();
			throw new RuntimeException($"{exn.Message}{Environment.NewLine}{exn.ErrorRecord.InvocationInfo.PositionMessage}", exn);
		}
		protected void WriteException(Exception exception, object target)
		{
			WriteError(new ErrorRecord(exception, "Ldbc", ErrorCategory.NotSpecified, target));
		}
		protected ILiteDatabase ResolveDatabase()
		{
			var value = Actor.BaseObject(GetVariableValue(Actor.DatabaseVariable));
			if (value is ILiteDatabase database)
				return database;

			throw new PSInvalidOperationException("Specify a database by the parameter or variable Database.");
		}
	}

	class InputParameters
	{
		public readonly BsonDocument Parameters;
		public readonly BsonValue[] Arguments;

		public InputParameters(object value)
		{
			value = Actor.BaseObject(value);
			if (value == null)
				return;

			if (value is IDictionary dic)
			{
				Parameters = Actor.ToBsonDocumentFromDictionary(dic);
			}
			else if (value is IList list)
			{
				Arguments = new BsonValue[list.Count];
				for (int i = 0; i < list.Count; ++i)
					Arguments[i] = Actor.ToBsonValue(list[i]);
			}
			else
			{
				Arguments = new BsonValue[] { Actor.ToBsonValue(value) };
			}
		}

		public BsonExpression Expression(string value)
		{
			if (Parameters != null)
				return BsonExpression.Create(value, Parameters);

			if (Arguments != null)
				return BsonExpression.Create(value, Arguments);

			return BsonExpression.Create(value);
		}
	}

	/// <summary>
	/// Common parameter -As.
	/// </summary>
	class ParameterAs
	{
		readonly Type Type;

		public static Func<BsonDocument, object> GetConvert(ParameterAs value)
		{
			// default wrap by Dictionary
			if (value == null || value.Type == typeof(Dictionary))
				return x => new Dictionary(x);

			// convert to PSObject
			if (value.Type == typeof(PSObject))
				return x => PSObjectSeializer.ReadCustomObject(x);

			// return BsonDocument as is
			if (value.Type == typeof(BsonDocument))
				return x => x;

			// deserialize
			return x => BsonMapper.Global.Deserialize(value.Type, x);
		}

		public ParameterAs(object value)
		{
			value = Actor.BaseObject(value);
			if (value == null)
			{
				Type = typeof(Dictionary);
				return;
			}

			if (value is Type type)
			{
				Type = type;
				return;
			}

			if (LanguagePrimitives.TryConvertTo(value, out OutputType alias))
			{
				switch (alias)
				{
					case OutputType.Default:
						Type = typeof(Dictionary);
						return;
					case OutputType.PS:
						Type = typeof(PSObject);
						return;
				}
			}

			Type = (Type)LanguagePrimitives.ConvertTo(value, typeof(Type), null);
		}
	}
}
