﻿
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using LiteDB;
using System;
using System.Management.Automation;

namespace Ldbc.Commands
{
	[Cmdlet(VerbsCommon.Get, "LiteData", DefaultParameterSetName = nsData)]
	[OutputType(typeof(Dictionary))]
	public sealed class GetDataCommand : Abstract
	{
		const string nsData = "Data";
		const string nsCount = "Count";

		[Parameter(Position = 0, Mandatory = true)]
		public ILiteCollection<BsonDocument> Collection { get; set; }

		[Parameter(Position = 1)]
		public object Filter { set { _Filter = Expression.Create(value); } }
		Expression _Filter;

		[Parameter(ParameterSetName = nsData)]
		public object Select { set { _Select = Expression.Create(value); } }
		Expression _Select;

		[Parameter(ParameterSetName = nsData)]
		public object OrderBy { set { _OrderBy = Expression.Create(value); } }
		Expression _OrderBy;

		[Parameter(ParameterSetName = nsData)]
		public int Order { get; set; }

		[Parameter(Mandatory = true, ParameterSetName = nsCount)]
		public SwitchParameter Count { get; set; }

		[Parameter(ParameterSetName = nsData)]
		public int First { get; set; }

		[Parameter(ParameterSetName = nsData)]
		public int Last { get; set; }

		[Parameter(ParameterSetName = nsData)]
		public int Skip { get; set; }

		[Parameter(ParameterSetName = nsData)]
		public object As { set { _As = new ParameterAs(value); } }
		ParameterAs _As;

		int GetCount()
		{
			return _Filter == null ? Collection.Count() : Collection.Count(_Filter.BsonExpression);
		}

		bool DoLast()
		{
			if (Last <= 0)
				return false;

			Skip = GetCount() - Skip - Last;
			First = Last;
			if (Skip >= 0)
				return false;

			First += Skip;
			if (First <= 0)
				return true;

			Skip = 0;
			return false;
		}

		protected override void BeginProcessing()
		{
			if (First > 0 && Last > 0)
				throw new PSArgumentException("Parameters First and Last cannot be specified together.");

			if (Count)
			{
				WriteObject(GetCount());
				return;
			}

			if (DoLast())
				return;

			var query = Collection.Query();

			// Filter
			if (_Filter != null)
				query = query.Where(_Filter.BsonExpression);

			// OrderBy
			if (_OrderBy != null)
				query = query.OrderBy(_OrderBy.BsonExpression, Order < 0 ? -1 : 1);

			// Select and Skip
			ILiteQueryableResult<BsonDocument> result;
			if (_Select != null)
				result = query.Select(_Select.BsonExpression).Skip(Skip);
			else
				result = query.Skip(Skip);

			// First
			if (First > 0)
				result = result.Limit(First);

			var convert = ParameterAs.GetConvert(_As);
			foreach (var doc in result.ToEnumerable())
				WriteObject(convert(doc));
		}
	}
}
