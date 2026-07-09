/*******************************************************************************
 * demo_tasks.c -- LED pattern generators (pure logic, no hardware access).
 *
 * Author: Urvish Kosta
 * License: MIT (see LICENSE at repository root)
 ******************************************************************************/
#include "demo_tasks.h"

/* ------------------------------------------------------------------ Cylon */
void cylon_init(cylon_state_t *s)
{
    s->pos = 0;
    s->dir = 1;
}

uint8_t cylon_step(cylon_state_t *s)
{
    uint8_t pattern = (uint8_t)(1u << s->pos);

    /* Bounce at the ends. */
    if (s->pos == 7 && s->dir > 0) {
        s->dir = -1;
    } else if (s->pos == 0 && s->dir < 0) {
        s->dir = 1;
    }
    s->pos = (uint8_t)((int8_t)s->pos + s->dir);

    return pattern;
}

/* ----------------------------------------------------------------- Scroll */
void scroll_init(scroll_state_t *s)
{
    s->pos = 0;
}

uint8_t scroll_step(scroll_state_t *s)
{
    uint8_t pattern = (uint8_t)(1u << s->pos);

    s->pos = (uint8_t)((s->pos + 1u) & 7u);   /* wrap 7 -> 0 */

    return pattern;
}
