/*******************************************************************************
 * test_demo_tasks.c -- host-side Unity tests for the LED pattern generators.
 *
 * These run on the development host (no target hardware needed):
 *
 *   cd firmware/test && make
 *
 * The pattern generators in demo_tasks.c are pure functions, so their whole
 * behaviour -- bounce at the ends, wrap-around, one-hot output -- can be
 * verified exhaustively here before the firmware ever touches the FPGA.
 *
 * Author: Urvish Kosta
 * License: MIT (see LICENSE at repository root)
 ******************************************************************************/
#include "unity.h"
#include "demo_tasks.h"

void setUp(void)    {}
void tearDown(void) {}

/* ------------------------------------------------------------------ Cylon */

static void test_cylon_starts_at_led0(void)
{
    cylon_state_t s;
    cylon_init(&s);
    TEST_ASSERT_EQUAL_HEX8(0x01, cylon_step(&s));
}

static void test_cylon_walks_up_then_bounces(void)
{
    cylon_state_t s;
    cylon_init(&s);

    /* 0 -> 7 */
    for (int i = 0; i < 8; i++) {
        TEST_ASSERT_EQUAL_HEX8((uint8_t)(1u << i), cylon_step(&s));
    }
    /* bounce: 6 -> 0 */
    for (int i = 6; i >= 0; i--) {
        TEST_ASSERT_EQUAL_HEX8((uint8_t)(1u << i), cylon_step(&s));
    }
    /* and back up again: 1 */
    TEST_ASSERT_EQUAL_HEX8(0x02, cylon_step(&s));
}

static void test_cylon_output_is_always_one_hot(void)
{
    cylon_state_t s;
    cylon_init(&s);

    for (int i = 0; i < 1000; i++) {
        uint8_t p = cylon_step(&s);
        /* exactly one bit set: p != 0 and p & (p-1) == 0 */
        TEST_ASSERT_NOT_EQUAL(0, p);
        TEST_ASSERT_EQUAL_HEX8(0, (uint8_t)(p & (uint8_t)(p - 1u)));
    }
}

static void test_cylon_period_is_14_steps(void)
{
    /* A full bounce cycle over 8 LEDs visits 14 distinct positions
     * (0..7 then 6..1) before repeating. */
    cylon_state_t s;
    cylon_init(&s);

    uint8_t first = cylon_step(&s);
    for (int i = 0; i < 13; i++) {
        (void)cylon_step(&s);
    }
    TEST_ASSERT_EQUAL_HEX8(first, cylon_step(&s));
}

/* ----------------------------------------------------------------- Scroll */

static void test_scroll_starts_at_led0(void)
{
    scroll_state_t s;
    scroll_init(&s);
    TEST_ASSERT_EQUAL_HEX8(0x01, scroll_step(&s));
}

static void test_scroll_wraps_after_led7(void)
{
    scroll_state_t s;
    scroll_init(&s);

    for (int i = 0; i < 8; i++) {
        TEST_ASSERT_EQUAL_HEX8((uint8_t)(1u << i), scroll_step(&s));
    }
    /* wraps back to LED0 */
    TEST_ASSERT_EQUAL_HEX8(0x01, scroll_step(&s));
}

static void test_scroll_output_is_always_one_hot(void)
{
    scroll_state_t s;
    scroll_init(&s);

    for (int i = 0; i < 1000; i++) {
        uint8_t p = scroll_step(&s);
        TEST_ASSERT_NOT_EQUAL(0, p);
        TEST_ASSERT_EQUAL_HEX8(0, (uint8_t)(p & (uint8_t)(p - 1u)));
    }
}

/* ------------------------------------------------------------------- main */

int main(void)
{
    UNITY_BEGIN();
    RUN_TEST(test_cylon_starts_at_led0);
    RUN_TEST(test_cylon_walks_up_then_bounces);
    RUN_TEST(test_cylon_output_is_always_one_hot);
    RUN_TEST(test_cylon_period_is_14_steps);
    RUN_TEST(test_scroll_starts_at_led0);
    RUN_TEST(test_scroll_wraps_after_led7);
    RUN_TEST(test_scroll_output_is_always_one_hot);
    return UNITY_END();
}
