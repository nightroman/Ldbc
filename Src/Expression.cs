
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using LiteDB;
using System;
using System.Collections;

namespace Ldbc
{
	public sealed class Expression
	{
		public BsonExpression BsonExpression { get; private set; }

		Dictionary _Parameters;
		public Dictionary Parameters
		{
			get
			{
				if (_Parameters == null)
					_Parameters = new Dictionary(BsonExpression.Parameters);

				return _Parameters;
			}
		}

		public Expression(string expression)
		{
			if (expression == null)
				throw new ArgumentNullException(nameof(expression));

			BsonExpression = BsonExpression.Create(expression);
		}

		public Expression(BsonExpression expression)
		{
			BsonExpression = expression ?? throw new ArgumentNullException(nameof(expression));
		}

		public Expression(string expression, IDictionary parameters)
		{
			if (expression == null)
				throw new ArgumentNullException(nameof(expression));
			if (parameters == null)
				throw new ArgumentNullException(nameof(parameters));

			var parameters2 = Actor.ToBsonDocumentFromDictionary(parameters);
			BsonExpression = BsonExpression.Create(expression, parameters2);
		}

		internal static Expression Create(object[] input)
		{
			if (input == null)
				throw new ArgumentNullException(nameof(input));

			if (input.Length == 2)
				return new Expression((string)input[0], (IDictionary)input[1]);

			if (input.Length != 1)
				throw new ArgumentException("Expected one or two items.");

			if (input[0] is string text)
			{
				return new Expression(text);
			}
			else if (input[0] is Expression expr1)
			{
				return expr1;
			}
			else if (input[0] is BsonExpression expr2)
			{
				return new Expression(expr2);
			}
			else
			{
				throw new ArgumentException(Res.CannotConvert2(input[0], "expression"));
			}
		}
	}
}
