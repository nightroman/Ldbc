
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
}
