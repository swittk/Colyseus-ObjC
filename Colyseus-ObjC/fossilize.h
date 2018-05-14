//
//  fossilize.h
//  Colyseus-ObjC
//
//  Created by Switt Kongdachalert on 12/5/18.
//  Copyright © 2018 Switt's Software. All rights reserved.
//

#ifndef fossilize_h
#define fossilize_h


void *fossil_malloc(size_t n);
void *fossil_realloc(void *p, size_t n);
static const char *print16(const char *z);
static unsigned int checksum(const char *zIn, size_t N);
int delta_apply(
                const char *zSrc,      /* The source or pattern file */
                int lenSrc,            /* Length of the source file */
                const char *zDelta,    /* Delta to apply to the pattern */
                int lenDelta,          /* Length of the delta */
                char *zOut             /* Write the output into this preallocated buffer */
);
int delta_create(const char *zSrc, /* The source or pattern file */ unsigned int lenSrc, /* Length of the source file */ const char *zOut, /* The target file */ unsigned int lenOut, /* Length of the target file */ char *zDelta /* Write the delta into this buffer */ );
int delta_output_size(const char *zDelta, int lenDelta);
static int digit_count(int v);
void fossil_free(void *p);
static unsigned int getInt(const char **pz, int *pLen);
static void putInt(unsigned int v, char **pz);

#endif /* fossilize_h */
