
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
		const string nsById= "ById";
		const string nsCount = "Count";

		[Parameter(Position = 0, Mandatory = true)]
		public ILiteCollection<BsonDocument> Collection { get; set; }

		[Parameter(Position = 1, ParameterSetName = nsData)]
		[Parameter(Position = 1, ParameterSetName = nsCount)]
		public object Where { set { _Where = Expression.Create(value); } }
		Expression _Where;

		[Parameter(ParameterSetName = nsById, Mandatory = true)]
		public object ById { get; set; }

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
		[Parameter(ParameterSetName = nsById)]
		public object As { set { _As = new ParameterAs(value); } }
		ParameterAs _As;

		int GetCount()
		{
			return _Where == null ? Collection.Count() : Collection.Count(_Where.BsonExpression);
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

		void DoById()
		{
			var doc = Collection.FindById(Actor.ToBsonValue(ById));
			if (doc != null)
			{
				var convert = ParameterAs.GetConvert(_As);
				WriteObject(convert(doc));
			}
		}

		protected override void BeginProcessing()
		{
			// case: ById
			if (ById != null)
			{
				DoById();
				return;
			}

			if (First > 0 && Last > 0)
				throw new PSArgumentException("Parameters First and Last cannot be specified together.");

			// case: Count
			if (Count)
			{
				WriteObject(GetCount());
				return;
			}

			// case? Last
			if (DoLast())
				return;

			var query = Collection.Query();

			// Filter
			if (_Where != null)
				query = query.Where(_Where.BsonExpression);

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
