/* $Id: ex05.mc,v 2.1 2005/06/14 22:16:47 jls Exp $ */

/*
 * Copyright 2005 SRC Computers, Inc.  All Rights Reserved.
 *
 *	Manufactured in the United States of America.
 *
 * SRC Computers, Inc.
 * 4240 N Nevada Avenue
 * Colorado Springs, CO 80907
 * (v) (719) 262-0213
 * (f) (719) 262-0223
 *
 * No permission has been granted to distribute this software
 * without the express permission of SRC Computers, Inc.
 *
 * This program is distributed WITHOUT ANY WARRANTY OF ANY KIND.
 */

#include <libmap.h>


void subr (int64_t In[], int64_t Out[], int64_t Counts[], int nvec, int64_t *time, int mapnum) {

    OBM_BANK_A (AL,      int64_t, MAX_OBM_SIZE)
    OBM_BANK_B (BL,      int64_t, MAX_OBM_SIZE)
    OBM_BANK_C (CountsL, int64_t, MAX_OBM_SIZE)

    int64_t t0, t1, t2;
    int i,n,total_nsamp,istart,cnt;
    
    Stream_64 SC,SA,SOut;

    read_timer (&t0);

#pragma src parallel sections
{
#pragma src section
{
    streamed_dma_cpu_64 (&SC, PORT_TO_STREAM, Counts, nvec*sizeof(int64_t));
}
#pragma src section
{
    int i;
    int64_t i64;

    for (i=0;i<nvec;i++)  {
       get_stream_64 (&SC, &i64);
       CountsL[i] = i64;
       cg_accum_add_32 (i64, 1, 0, i==0, &total_nsamp);
    }
}
}

#pragma src parallel sections
{
#pragma src section
{
    streamed_dma_cpu_64 (&SA, PORT_TO_STREAM, In, total_nsamp*sizeof(int64_t));
}
#pragma src section
{
    int i;
    int64_t i64;

    for (i=0;i<total_nsamp;i++)  {
       get_stream_64 (&SA, &i64);
       AL[i] = i64;
    }
}
}

    read_timer (&t1);

    istart = 0;
    for (n=0;n<nvec;n++)  {

      cnt = CountsL[n];

      for (i=0; i<cnt; i++) {
        BL[i+istart] = AL[i+istart] + n*10000;
      }

      istart = istart + cnt;
    }

    read_timer (&t2);

    *time = t1 - t0;

#pragma src parallel sections
{
#pragma src section
{
    int i;
    int64_t i64,j64;

    for (i=0;i<total_nsamp;i++)  {
       i64 = BL[i];
       put_stream_64 (&SOut, i64, 1);
    }
}
#pragma src section
{
    streamed_dma_cpu_64 (&SOut, STREAM_TO_PORT, Out, total_nsamp*sizeof(int64_t));
}
}
    }
