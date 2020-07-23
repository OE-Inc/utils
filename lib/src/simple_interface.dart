
typedef Runnable = void Function();

typedef Callable1<PARAM, RETURN> = RETURN Function(PARAM arg);
typedef Callable2<PARAM1, PARAM2, RETURN> = RETURN Function(PARAM1 arg1, PARAM2 arg2);
typedef Callable3<PARAM1, PARAM2, PARAM3, RETURN> = RETURN Function(PARAM1 arg1, PARAM2 arg2, PARAM3 arg3);

typedef ValueGetter<TYPE> = TYPE Function(TYPE oldVal);

typedef KeyValueGetter<KEY, VAL> = VAL Function(KEY key, VAL oldVal, int lastUpd);

