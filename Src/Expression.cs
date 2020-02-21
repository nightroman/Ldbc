
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using LiteDB;
using System;
using System.Linq;
using System.Collections;

namespace Ldbc
{
	public sealed class Expression
	{
		readonly BsonExpression _expression;
		Dictionary _Parameters;

		public Dictionary Parameters
		{
			get
			{
				return _Parameters ?? (_Parameters = new Dictionary(_expression.Parameters));
			}
		}

		[Obsolete("Designed for scripts.")]
		public static implicit operator BsonExpression(Expression value)
		{
			return value?._expression;
		}

		public BsonExpression ToBsonExpression()
		{
			return _expression;
		}

		public Expression(string expression)
		{
			if (expression == null)
				throw new ArgumentNullException(nameof(expression));

			_expression = BsonExpression.Create(expression);
		}

		public Expression(BsonExpression expression)
		{
			_expression = expression ?? throw new ArgumentNullException(nameof(expression));
		}

		public Expression(string expression, IDictionary parameters)
		{
			if (expression == null)
				throw new ArgumentNullException(nameof(expression));
			if (parameters == null)
				throw new ArgumentNullException(nameof(parameters));

			var parameters2 = Actor.ToBsonDocumentFromDictionary(parameters);
			_expression = BsonExpression.Create(expression, parameters2);
		}

		public Expression(string expression, params object [] args)
		{
			if (expression == null)
				throw new ArgumentNullException(nameof(expression));
			if (args == null)
				throw new ArgumentNullException(nameof(args));

			var args2 = new BsonValue[args.Length];
			for(var i = 0; i < args.Length; ++i)
				args2[i] = Actor.ToBsonValue(args[i]);

			_expression = BsonExpression.Create(expression, args2);
		}

		public override string ToString()
		{
			return _expression.ToString();
		}

		static void SetParameters(BsonDocument that, IDictionary parameters)
		{
			if (parameters == null)
				throw new ArgumentNullException(nameof(parameters));

			foreach (DictionaryEntry kv in parameters)
				that[kv.Key.ToString()] = Actor.ToBsonValue(kv.Value);
		}

		static void SetArguments(BsonDocument that, params object[] args)
		{
			if (args == null)
				throw new ArgumentNullException(nameof(args));

			for (var i = 0; i < args.Length; ++i)
				that[$"{i}"] = Actor.ToBsonValue(args[i]);
		}

		internal static BsonExpression Input(object value)
		{
			if (value == null)
				throw new ArgumentNullException(nameof(value));

			if (value is string text)
				return BsonExpression.Create(text);

			if (value is BsonExpression expr1)
				return expr1;

			if (value is Expression expr2)
				return expr2.ToBsonExpression();

			if (value is IList list)
			{
				if (list.Count == 2 && list[1] is IDictionary dic)
				{
					var expr = Input(list[0]);
					SetParameters(expr.Parameters, dic);
					return expr;
				}

				if (list.Count >= 2)
				{
					var expr = Input(list[0]);
					SetArguments(expr.Parameters, list.Cast<object>().Skip(1).ToArray());
					return expr;
				}
			}

			throw new ArgumentException(Res.CannotConvert2(value, "expression"));
		}
	}
}
