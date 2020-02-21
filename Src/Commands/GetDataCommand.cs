
// Copyright (c) Roman Kuzmin
// http://www.apache.org/licenses/LICENSE-2.0

using LiteDB;
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
		public object Where { set { _Where = Expression.Input(value); } }
		BsonExpression _Where;

		[Parameter(ParameterSetName = nsById, Mandatory = true)]
		public object ById { get; set; }

		[Parameter(ParameterSetName = nsData)]
		[Parameter(ParameterSetName = nsById)]
		public object Select { set { _Select = Expression.Input(value); } }
		BsonExpression _Select;

		[Parameter(ParameterSetName = nsData)]
		[Parameter(ParameterSetName = nsById)]
		public string[] Include { set { _Include = value; } }
		string[] _Include;

		[Parameter(ParameterSetName = nsData)]
		public object OrderBy { set { _OrderBy = Expression.Input(value); } }
		BsonExpression _OrderBy;

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
			return _Where == null ? Collection.Count() : Collection.Count(_Where);
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
			// ById?
			if (ById != null)
			{
				// case: ById
				if (_Select == null)
				{
					DoById();
					return;
				}

				// make Where by id and take 1
				_Where = WhereIdExpression.Input(ById);
				First = 1;
			}
			else
			{
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
			}

			var query = Collection.Query();

			// Filter
			if (_Where != null)
				query = query.Where(_Where);

			// OrderBy
			if (_OrderBy != null)
				query = query.OrderBy(_OrderBy, Order < 0 ? -1 : 1);

			// Include
			if (_Include != null)
			{
				foreach (var it in _Include)
					query = query.Include(BsonExpression.Create(it));
			}

			// Select and Skip
			ILiteQueryableResult<BsonDocument> result;
			if (_Select != null)
				result = query.Select(_Select).Skip(Skip);
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
