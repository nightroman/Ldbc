using LiteDB;
using System.Management.Automation;

namespace Ldbc.Commands;

[Cmdlet(VerbsCommon.Get, "LiteData", DefaultParameterSetName = nsData)]
[OutputType(typeof(Dictionary))]
public sealed class GetDataCommand : Abstract
{
    const string nsData = "Data";
    const string nsById = "ById";
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
    public object GroupBy { set { _GroupBy = Expression.Input(value); } }
    BsonExpression _GroupBy;

    [Parameter(ParameterSetName = nsData)]
    public object[] OrderBy { set { SetOrderBy(value); } }
    List<QueryOrder> _OrderBy;

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

    void SetOrderBy(object[] values)
    {
        _OrderBy = [];
        for (int i = 0; i < values.Length; i++)
        {
            // expression
            var exp = Expression.Input(values[i]);

            // try next value as order
            int ord = 0;
            if (i < values.Length - 1)
            {
                int n = Expression.Order(values[i + 1]);
                if (n != 0)
                {
                    ++i;
                    ord = n;
                }
            }

            //! order: if defined (< 0) then descending else ascending (default)
            _OrderBy.Add(new(exp, ord < 0 ? -1 : 1));
        }
    }

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

        var query = new Query();

        // Select
        if (_Select != null)
            query.Select = _Select;

        // Include
        if (_Include != null)
        {
            foreach (var it in _Include)
                query.Includes.Add(BsonExpression.Create(it));
        }

        // Where
        if (_Where != null)
            query.Where.Add(_Where);

        // GroupBy
        if (_GroupBy != null)
            query.GroupBy = _GroupBy;

        // OrderBy
        if (_OrderBy != null)
            query.OrderBy.AddRange(_OrderBy);

        //! https://github.com/mbdavid/LiteDB/issues/1506
        // Skip & First
        var skip = Skip > 0 ? Skip : 0;
        var limit = First > 0 ? First : int.MaxValue;

        var convert = ParameterAs.GetConvert(_As);
        foreach (var doc in Collection.Find(query, skip, limit))
            WriteObject(convert(doc));
    }
}
