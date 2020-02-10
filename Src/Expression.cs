
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

		internal static Expression Create(object value)
		{
			if (value == null)
				throw new ArgumentNullException(nameof(value));

			if (value is Expression expr1)
				return expr1;

			if (value is BsonExpression expr2)
				return new Expression(expr2);

			if (value is string text)
				return new Expression(text);

			if (value is IList list && list.Count == 2)
				return new Expression((string)list[0], (IDictionary)list[1]);

			throw new ArgumentException(Res.CannotConvert2(value, "expression"));
		}
	}
}
