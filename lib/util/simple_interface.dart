
/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Right Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Right Reserved.
 */

typedef Runnable = void Function();

typedef Callable<RETURN> = RETURN Function();
typedef Callable1<PARAM, RETURN> = RETURN Function(PARAM arg);
typedef Callable2<PARAM1, PARAM2, RETURN> = RETURN Function(PARAM1 arg1, PARAM2 arg2);
typedef Callable3<PARAM1, PARAM2, PARAM3, RETURN> = RETURN Function(PARAM1 arg1, PARAM2 arg2, PARAM3 arg3);

typedef ValueGetter<TYPE> = TYPE Function(TYPE? oldVal);

typedef KeyValueGetter<KEY, VAL> = VAL Function(KEY key, VAL? oldVal, int lastUpd);

